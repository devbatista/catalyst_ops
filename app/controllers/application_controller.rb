class ApplicationController < ActionController::Base
  before_action :custom_authenticate_user!
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

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :role])
  end
end
