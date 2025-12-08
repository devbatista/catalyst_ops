class Register::SignupsController < ApplicationController
  layout false # se quiser página limpa
  skip_authorization_check

  def new
    @company = Company.new
    @user = User.new
    @payment_methods = %w[pix credit_card boleto]
  end

  def create
    @payment_methods = %w[pix credit_card boleto]
    @company = Company.new(company_params)
    @user = User.new(user_params.merge(company: @company, role: :gestor))

    if @company.valid? && @user.valid?
      ActiveRecord::Base.transaction do
        @company.save!
        @user.save!
      end

      chosen = Array(params[:signup][:payment_methods]) # ["pix","credit_card","boleto"]

      if chosen.include?("credit_card")
        # esboço: redireciona ao init_point (assinatura/plano)
        init_point = MercadoPago::Subscriptions.start!(
          company: @company,
          payer_email: @user.email,
          amount: 99.90,
          reason: "CatalystOps - Plano Mensal",
          back_url: register_success_url(subdomain: "register")
        )
        redirect_to init_point, allow_other_host: true
      elsif chosen.include?("pix")
        # esboço: gera QRCode via API de pagamentos (preferencialmente Payment intent PIX)
        qr = MercadoPago::Pix.generate_qr(amount: 99.90, description: "CatalystOps - PIX", external_reference: "signup_#{@company.id}")
        @qr_data = qr # exibir na view success
        redirect_to register_success_path(subdomain: "register", qr: true)
      else
        # boleto ou fallback
        redirect_to register_success_path(subdomain: "register")
      end
    else
      render :new, status: :unprocessable_entity
    end
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
end