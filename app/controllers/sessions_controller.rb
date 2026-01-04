class SessionsController < Devise::SessionsController
  layout false

  skip_before_action :custom_authenticate_user!
  skip_authorization_check

  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.downcase.strip)
    if user&.active? && user&.valid_password?(params[:password])
      sign_in(:user, user)

      if user.admin?
        redirect_to admin_dashboard_url(subdomain: "admin"),
                    allow_other_host: true,
                    notice: "Login realizado com sucesso!"
      else
        redirect_to app_dashboard_url(subdomain: "app"),
                    allow_other_host: true,
                    notice: "Login realizado com sucesso!"
      end
    else
      flash[:alert] = "E-mail ou senha inválidos."
      redirect_to login_root_url(subdomain: "login"), allow_other_host: true
    end
  end

  def new_password; end

  def update_password
    user = User.reset_password_by_token(
      reset_password_token: params[:reset_password_token],
      password: params[:password],
      password_confirmation: params[:password_confirmation],
    )

    if user.errors.empty?
      user.activate!
      flash[:notice] = "Senha alterada com sucesso! Faça o login."
      redirect_to login_root_url(subdomain: "login"), allow_other_host: true
    else
      flash.now[:alert] = user.errors.full_messages.to_sentence
      @token = params[:reset_password_token]
      render :new_password, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out(current_user)
    redirect_to login_root_url(subdomain: "login"), allow_other_host: true, notice: "Logout realizado com sucesso!"
  end

  def require_no_authentication
    return unless current_user

    if current_user.admin?
      unless request.subdomain == "admin"
        redirect_to admin_dashboard_url(subdomain: "admin"), allow_other_host: true and return
      end
    else
      unless request.subdomain == "app"
        redirect_to app_dashboard_url(subdomain: "app"), allow_other_host: true and return
      end
    end
  end
end
