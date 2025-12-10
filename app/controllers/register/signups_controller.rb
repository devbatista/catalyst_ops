class Register::SignupsController < ApplicationController
  layout false
  skip_authorization_check

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
      plan_id: signup_params[:plan_id],
      payment_method: signup_params[:payment_method]
    ))
    @user = User.new(user_params.merge(company: @company, role: :gestor))

    result = save_register(@company, @user)

    unless result.success?
      flash.now[:alert] = result.errors
      return render :new, status: :unprocessable_entity
    end

    payment_method = signup_params[:payment_method].to_s
    handle_payment_flow(@company, @user, payment_method)
  end

  def success
    # exibe confirmação e QRCode se qr=true
  end

  private

  def company_params
    params.require(:signup).require(:company).permit(
      :name, :document, :email, :phone,
      :address, :state_registration, :municipal_registration, :website
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
      company_res = Cmd::Companies::Create.new(company).call
      user_res = Cmd::Users::Create.new(user).call

      if company_res.success? && user_res.success?
        return Result.new(true, nil)
      else
        errors = [company_res.errors] + [user_res.errors].compact.flatten
        raise ActiveRecord::Rollback, errors.join(", ")
      end
    end
    Result.new(true, nil)
  rescue ActiveRecord::RecordInvalid => e
    Result.new(false, e.message.presence || (Array(company.errors.full_messages) + Array(user.errors.full_messages)))
  end

  def handle_payment_flow(company, user, payment_method)
    case payment_method
    when "boleto"
      # boleto
    when "pix"
      # pix
    when "credit_card"
      # credit_card
    else
      redirect_to register_signup_success_path(company_id: company.id, user_id: user.id)
    end
    
  end
end