class Mobile::V1::BaseController < ActionController::API
  before_action :authenticate_mobile_user!

  attr_reader :current_mobile_session
  attr_reader :current_mobile_user

  private

  def authenticate_mobile_user!
    token = bearer_token
    return render_unauthorized("Token de acesso não informado.") if token.blank?

    session = MobileApiSession.find_active_by_raw_token(token)
    return render_unauthorized("Token inválido ou expirado.") if session.blank?

    user = session.user
    return render_unauthorized("Usuário inativo.") unless user.active?
    return render_unauthorized("Acesso da empresa está desativado.") unless user.access_enabled?

    @current_mobile_session = session
    @current_mobile_user = user
    touch_mobile_session_usage
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    return if header.blank?

    scheme, token = header.split(" ", 2)
    return if scheme.to_s.downcase != "bearer"

    token
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end

  def touch_mobile_session_usage
    return if current_mobile_session.blank?

    current_mobile_session.update_column(:last_used_at, Time.current)
  end
end
