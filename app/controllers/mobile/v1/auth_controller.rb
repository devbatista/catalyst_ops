class Mobile::V1::AuthController < Mobile::V1::BaseController
  skip_before_action :authenticate_mobile_user!, only: [:login]

  TOKEN_TTL = 30.days

  def login
    email = params[:email].to_s.downcase.strip
    password = params[:password].to_s

    user = User.find_by(email: email)
    return login_error!(email: email, user: user, message: "Credenciais inválidas.", status: :unauthorized) if user.blank? || !user.valid_password?(password)
    return login_error!(email: email, user: user, message: "Usuário inativo.", status: :forbidden) unless user.active?
    return login_error!(email: email, user: user, message: "Acesso da empresa está desativado.", status: :forbidden) unless user.access_enabled?

    expires_at = (Time.current + TOKEN_TTL).end_of_day
    token = MobileApiSession.issue_for!(user: user, expires_at: expires_at)
    Current.user = user
    Current.source = "mobile"
    Audit::AuthLogger.login_succeeded(user: user)

    render json: {
      token: token,
      token_type: "Bearer",
      expires_at: expires_at.iso8601,
      user: mobile_user_payload(user)
    }, status: :ok
  end

  def me
    mobile_audit(
      action: "mobile.api.auth.me.viewed",
      metadata: { user_id: current_mobile_user.id }
    )

    render json: { user: mobile_user_payload(current_mobile_user) }, status: :ok
  end

  def logout
    current_mobile_session&.revoke!
    Audit::AuthLogger.logout_succeeded(user: current_mobile_user)
    render json: { message: "Logout realizado com sucesso." }, status: :ok
  end

  def logout_all
    current_mobile_user.mobile_api_sessions.active.update_all(revoked_at: Time.current, updated_at: Time.current)
    mobile_audit(
      action: "mobile.api.auth.logout_all.succeeded",
      metadata: { user_id: current_mobile_user.id }
    )
    render json: { message: "Logout de todos os dispositivos realizado com sucesso." }, status: :ok
  end

  private

  def login_error!(email:, user:, message:, status:)
    Audit::AuthLogger.login_failed(email: email, user: user)
    render json: { error: message }, status: status
  end

  def mobile_user_payload(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      company: {
        id: user.company_id,
        name: user.company&.name
      }
    }
  end
end
