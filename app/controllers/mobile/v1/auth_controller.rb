class Mobile::V1::AuthController < Mobile::V1::BaseController
  skip_before_action :authenticate_mobile_user!, only: [:login]

  TOKEN_TTL = 30.days

  def login
    email = params[:email].to_s.downcase.strip
    password = params[:password].to_s

    user = User.find_by(email: email)
    if user.blank? || !user.valid_password?(password)
      return render json: { error: "Credenciais inválidas." }, status: :unauthorized
    end

    unless user.active?
      return render json: { error: "Usuário inativo." }, status: :forbidden
    end

    unless user.access_enabled?
      return render json: { error: "Acesso da empresa está desativado." }, status: :forbidden
    end

    expires_at = (Time.current + TOKEN_TTL).end_of_day
    token = MobileApiSession.issue_for!(user: user, expires_at: expires_at)

    render json: {
      token: token,
      token_type: "Bearer",
      expires_at: expires_at.iso8601,
      user: mobile_user_payload(user)
    }, status: :ok
  end

  def me
    render json: { user: mobile_user_payload(current_mobile_user) }, status: :ok
  end

  def logout
    current_mobile_session&.revoke!
    render json: { message: "Logout realizado com sucesso." }, status: :ok
  end

  def logout_all
    current_mobile_user.mobile_api_sessions.active.update_all(revoked_at: Time.current, updated_at: Time.current)
    render json: { message: "Logout de todos os dispositivos realizado com sucesso." }, status: :ok
  end

  private

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
