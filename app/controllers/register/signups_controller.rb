class Register::SignupsController < ApplicationController
  layout false
  skip_authorization_check

  Result = Struct.new(:success?, :errors)

  before_action :sanitize_phone, only: :create

  def new
    @company = Company.new
    @user = User.new
    @payment_methods = %w[pix credit_card boleto]
    @plans = Plan.where(status: :active).order(:transaction_amount)
  end

  def create
    @payment_methods = %w[pix credit_card boleto]
    @company = Company.new(company_params.merge(
      plan_id: params.dig(:signup, :plan_id),
      payment_method: params.dig(:signup, :payment_method)
    ))
    @user = User.new(user_params.merge(role: :gestor))

    result = save_register(@company, @user)

    unless result.success?
      flash.now[:alert] = result.errors
      return render :new, status: :unprocessable_entity
    end

    payment_method = params[:payment_method].to_s
    handle_payment_flow(@company, payment_method)
    
    redirect_to success_path(company_id: @company.id)
  end

  def success
    company = Company.find_by(id: params[:company_id])

    unless company
      redirect_to root_path, alert: "Erro no cadastro ou empresa já cadastrada, verifique com nosso suporte."
    end
  end

  private

  def company_params
    params.require(:signup).require(:company).permit(
      :name, :document, :email, :phone,
      :zip_code, :street_name, :street_number, :complement, :neighborhood, :city, :federal_unit,
      :state_registration, :municipal_registration, :website
    )
  end

  def user_params
    params.require(:signup).require(:user).permit(:name, :email, :password, :password_confirmation)
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
      binding.pry
      company_res = Cmd::Companies::Create.new(company).call
      unless company_res.success?
        raise ActiveRecord::Rollback, Array(company_res.errors).join(", ")
      end

      user.company = company
      user_res = Cmd::Users::Create.new(user).call
      unless user_res.success?
        raise ActiveRecord::Rollback, Array(user_res.errors).join(", ")
      end

      company.update_attribute(:responsible_id, user.id)

      return Result.new(true, nil)
    end
    Result.new(true, nil)
  rescue => e
    Result.new(false,
               e.message.presence || (Array(company.errors.full_messages) + Array(user.errors.full_messages)))
  end

  def handle_payment_flow(company, payment_method)
    case payment_method
    when "boleto"
      ::Payments::BoletoPaymentJob.perform_async(company.id)
    when "pix"
      ::Payments::PixPaymentJob.perform_async(company.id)
    when "credit_card"
      ::Payments::CreditCardPayment.perform_async(company.id)
    end
  end
end