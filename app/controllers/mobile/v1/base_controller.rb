class Mobile::V1::BaseController < ActionController::API
  before_action :authenticate_mobile_user!
  around_action :with_mobile_current_context

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

  def mobile_company
    current_mobile_user&.company
  end

  def mobile_audit(action:, resource: nil, metadata: {}, actor: nil, company: nil)
    resolved_actor = actor || current_mobile_user
    resolved_company = company || resolved_actor&.company || mobile_company

    Audit::Log.call(
      action: action,
      actor: resolved_actor,
      company: resolved_company,
      resource: resource,
      metadata: metadata
    )
  end

  def pagination_params(default_per: 20, max_per: 100)
    page = [params[:page].to_i, 1].max
    per = params[:per].to_i
    per = default_per if per <= 0
    per = max_per if per > max_per
    [page, per]
  end

  def render_paginated(data:, collection:)
    render json: {
      data: data,
      meta: {
        current_page: collection.current_page,
        total_pages: collection.total_pages,
        total_count: collection.total_count,
        per_page: collection.limit_value
      }
    }, status: :ok
  end

  def touch_mobile_session_usage
    return if current_mobile_session.blank?

    current_mobile_session.update_column(:last_used_at, Time.current)
  end

  def with_mobile_current_context
    Current.user = current_mobile_user
    Current.request_id = request.request_id
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
    Current.source = "mobile"
    yield
  ensure
    Current.reset
  end
end
