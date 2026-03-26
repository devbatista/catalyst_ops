class SessionsController < Devise::SessionsController
  layout false

  skip_before_action :custom_authenticate_user!
  skip_authorization_check

  before_action :reset_session, only: :confirm_signup

  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.downcase.strip)
    if user&.active? && user&.valid_password?(params[:password])
      sign_in(:user, user)
      log_audit_event!(
        action: "auth.login.succeeded",
        actor: user,
        company: user.company,
        resource: user,
        metadata: { subdomain: request.subdomain, path: request.path }
      )

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
      log_audit_event!(
        action: "auth.login.failed",
        actor: user,
        company: user&.company,
        resource: user,
        metadata: {
          subdomain: request.subdomain,
          path: request.path,
          failure_reason: login_failure_reason_for(user),
          attempted_email: params[:email].to_s.downcase.strip
        }
      )
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

  def confirm_signup
    token = params[:token].to_s
    user = User.find_signed(token, purpose: :signup_confirmation)

    if user.blank?
      redirect_to login_root_url(subdomain: "login"), allow_other_host: true,
                  alert: "Link de confirmação inválido ou expirado."
      return
    end

    user.activate! unless user.active?

    redirect_to login_root_url(subdomain: "login"), allow_other_host: true,
                notice: "Cadastro confirmado com sucesso! Faça o login."
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to login_root_url(subdomain: "login"), allow_other_host: true,
                alert: "Link de confirmação inválido ou expirado."
  end

  def destroy
    user = current_user
    sign_out(current_user)
    
    log_audit_event!(
      action: "auth.logout.succeeded",
      actor: user,
      company: user&.company,
      resource: user,
      metadata: { subdomain: request.subdomain, path: request.path }
    )
    
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

  private

  def login_failure_reason_for(user)
    return "user_not_found" if user.blank?
    return "inactive_user" unless user.active?
    return "invalid_password" unless user.valid_password?(params[:password])

    "unknown"
  end
end
