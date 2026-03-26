class ApplicationController < ActionController::Base
  before_action :custom_authenticate_user!, unless: :register_subdomain?
  before_action :block_inactive_company_access, if: :app_subdomain?
  before_action :ensure_terms_accepted!, if: :app_subdomain?
  before_action :configure_permitted_parameters, if: :devise_controller?

  check_authorization unless: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    flash[:alert] = exception.message
    if current_user&.admin?
      redirect_to admin_dashboard_url(subdomain: "admin")
    else
      redirect_to app_dashboard_url(subdomain: "app")
    end
  end

  protected

  def custom_authenticate_user!
    unless current_user && current_user.active?
      reset_session
      redirect_to login_root_url(subdomain: "login"), allow_other_host: true
    end
  end

  def block_inactive_company_access
    return unless current_user && current_user.company
    return if request.path == '/logout'

    unless current_user.company.access_enabled?
      reset_session
      redirect_to login_root_url(subdomain: "login"), alert: "Acesso da sua empresa está desativado. Por favor, entre em contato com o suporte.", allow_other_host: true
    end
  end

  def app_subdomain?
    request.subdomain == "app"
  end

  def register_subdomain?
    request.subdomain == "register"
  end

  def ensure_terms_accepted!
    return unless current_user&.company
    return if current_user.company.accepted_current_terms?
    return if controller_path == "app/terms_of_use"
    return if request.path == "/logout"

    redirect_to app_terms_of_use_path, alert: "Você precisa aceitar o contrato de utilização para continuar."
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :role])
  end

  def log_audit_event!(action:, actor: nil, company: nil, resource: nil, metadata: {})
    Audit::EventLogger.call(
      action: action,
      source: audit_source,
      actor: actor,
      company: company,
      resource: resource,
      metadata: metadata,
      request_id: request.request_id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  rescue StandardError => e
    Rails.logger.error("[ApplicationController] Falha ao registrar auditoria #{action}: #{e.message}")
  end

  def audit_source
    return "admin" if request.subdomain == "admin"
    return "app" if request.subdomain == "app"
    return "login" if request.subdomain == "login"
    return "webhook" if request.subdomain == "webhook"

    "system"
  end
end
