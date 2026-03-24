class Register::SignupsController < ApplicationController
  layout false
  skip_authorization_check

  Result = Struct.new(:success?, :errors)

  before_action :sanitize_phone, only: :create
  before_action :set_form_dependencies, only: [:new, :create]

  def new
    @company = Company.new
    @user = User.new
    @payment_methods = %w[pix credit_card boleto]
    @plans = Plan.where(status: :active).order(:transaction_amount)
    @coupon_code = nil
  end

  def create
    @payment_methods = %w[pix credit_card boleto]
    @coupon_code = params.dig(:signup, :coupon_code).to_s.upcase.strip
    @company = Company.new(company_params.merge(
      plan_id: params.dig(:signup, :plan_id),
      payment_method: params.dig(:signup, :payment_method)
    ))
    @company.require_terms_acceptance = true
    @company.terms_checkbox_accepted = terms_accepted?
    @user = User.new(user_params.merge(role: :gestor))
    coupon_result = resolve_coupon_result

    unless coupon_result.success?
      flash.now[:alert] = coupon_result.errors
      return render :new, status: :unprocessable_entity
    end

    result = save_register(@company, @user)

    unless result.success?
      flash.now[:alert] = result.errors
      return render :new, status: :unprocessable_entity
    end

    cc_token = @company.payment_method == "credit_card" ? params.dig(:signup, :card_token) : nil
    payment_result = handle_payment_flow(@company, @company.payment_method, cc_token, coupon_result)

    unless payment_result.success?
      return redirect_to success_path(company_id: @company.id),
                         alert: "Cadastro criado, mas houve falha ao iniciar o fluxo de pagamento: #{payment_result.errors}"
    end

    if trial_coupon_without_mercado_pago?(coupon_result)
      @user.send_signup_confirmation_email!
      return redirect_to success_path(company_id: @company.id, confirmation_email: "1")
    end

    @user.send_welcome_email! if should_send_welcome_email?(coupon_result)

    redirect_to success_path(company_id: @company.id)
  end

  def success
    company = Company.find_by(id: params[:company_id])

    unless company
      redirect_to root_path, alert: "Erro no cadastro ou empresa já cadastrada, verifique com nosso suporte."
    end

    if params[:confirmation_email] == "1"
      @success_message = "Foi enviado um link de confirmação de cadastro no email"
      @success_subtext = nil
      return
    end

    @success_message = "Foi enviado um email para sua conta com as informações de pagamento."
    @success_subtext = "Por favor, verifique sua caixa de entrada."
  end

  private

  def set_form_dependencies
    @payment_methods = %w[pix credit_card boleto]
    @plans = Plan.where(status: :active).order(:transaction_amount)
  end

  def company_params
    params.require(:signup).require(:company).permit(
      :name, :document, :email, :phone,
      :zip_code, :street, :number, :complement, :neighborhood, :city, :state,
      :state_registration, :municipal_registration, :website
    )
  end

  def user_params
    params.require(:signup).require(:user).permit(:name, :email, :password, 
                                                  :password_confirmation, :can_be_technician)
  end

  def subscription_params
    plan = Plan.find_by(id: params.dig(:signup, :plan_id))
    {
      preapproval_plan_id: plan&.external_id,
      reason: plan&.reason,
      transaction_amount: plan&.transaction_amount,
      external_reference: @company&.id&.to_s,
    }
  end

  def terms_accepted?
    params.dig(:signup, :accept_terms) == "1"
  end

  def resolve_coupon_result
    plan = Plan.find_by(id: params.dig(:signup, :plan_id))

    Coupons::SignupBenefitResolver.new(
      plan: plan,
      coupon_code: @coupon_code,
      company: @company,
      payment_method: params.dig(:signup, :payment_method)
    ).call
  end

  def sanitize_phone
    if params.dig(:signup, :company, :phone).present?
      phone = params[:signup][:company][:phone]
      sanitized = phone.gsub(/\D/, "")
      params[:signup][:company][:phone] = sanitized
    end
  end

  def save_register(company, user)
    ActiveRecord::Base.transaction do
      company_res = Cmd::Companies::Create.new(company).call
      raise ActiveRecord::Rollback, Array(company_res.errors).join(", ") unless company_res.success?

      user.company = company
      user_res = Cmd::Users::Create.new(user).call
      raise ActiveRecord::Rollback, Array(user_res.errors).join(", ") unless user_res.success?

      company.update_attribute(:responsible_id, user.id)
      company.accept_current_terms!(
        user: user,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      company.subscriptions.create!(subscription_params) || raise(ActiveRecord::Rollback, "Erro ao criar assinatura para a empresa.")

      return Result.new(true, nil)
    end
    Result.new(true, nil)
  rescue => e
    Result.new(false,
               e.message.presence || (Array(company.errors.full_messages) + Array(user.errors.full_messages)))
  end

  def handle_payment_flow(company, payment_method, cc_token = nil, coupon_result = nil)
    case payment_method
    when "boleto"
      handle_boleto_flow(company, coupon_result)
    when "pix"
      handle_pix_flow(company, coupon_result)
    when "credit_card"
      handle_credit_card_flow(company, cc_token, coupon_result)
    else
      Result.new(false, "Método de pagamento inválido.")
    end
  end

  def handle_boleto_flow(company, coupon_result)
    return activate_trial_coupon!(company, coupon_result) if coupon_result&.trial?

    ::CreateUser::BoletoPaymentJob.perform_later(
      company.id,
      coupon_id: coupon_result&.coupon&.id,
      original_amount: coupon_result&.original_amount,
      final_amount: coupon_result&.final_amount
    )
    Result.new(true, nil)
  end

  def handle_pix_flow(company, coupon_result)
    return activate_trial_coupon!(company, coupon_result) if coupon_result&.trial?

    ::CreateUser::PixPaymentJob.perform_later(
      company.id,
      coupon_id: coupon_result&.coupon&.id,
      original_amount: coupon_result&.original_amount,
      final_amount: coupon_result&.final_amount
    )
    Result.new(true, nil)
  end

  def handle_credit_card_flow(company, cc_token, coupon_result)
    return Result.new(false, "Token do cartão não informado.") if cc_token.blank?

    result =
      if coupon_result&.trial?
        ::Cmd::MercadoPago::CreateCreditCardTrialSubscription.new(company, cc_token, coupon_result.coupon).call
      else
        ::Cmd::MercadoPago::CreateCreditCardPayment.new(company, cc_token).call
      end

    return result unless result.success? && coupon_result&.coupon_applied?

    Coupons::Redeem.call(
      coupon: coupon_result.coupon,
      company: company,
      subscription: company.current_subscription,
      original_amount: coupon_result.original_amount,
      final_amount: coupon_result.final_amount
    )
    result
  rescue => e
    Result.new(false, e.message)
  end

  def activate_trial_coupon!(company, coupon_result)
    company.current_subscription.activate_for!(
      frequency: coupon_result.coupon.trial_frequency,
      frequency_type: coupon_result.coupon.trial_frequency_type
    )

    Coupons::Redeem.call(
      coupon: coupon_result.coupon,
      company: company,
      subscription: company.current_subscription,
      original_amount: coupon_result.original_amount,
      final_amount: coupon_result.final_amount
    )
    Result.new(true, nil)
  end

  def trial_coupon_without_mercado_pago?(coupon_result)
    coupon_result&.trial? && %w[pix boleto].include?(@company.payment_method)
  end

  def signup_without_coupon?(coupon_result)
    coupon_result.present? && !coupon_result.coupon_applied?
  end

  def should_send_welcome_email?(coupon_result)
    signup_without_coupon?(coupon_result) && @company.payment_method != "pix"
  end

end
