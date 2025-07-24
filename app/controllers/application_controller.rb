class ApplicationController < ActionController::Base
  before_action :custom_authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  check_authorization unless: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to app_root_path, alert: exception.message
  end

  protected

  def custom_authenticate_user!
    unless current_user
      redirect_to login_root_url(subdomain: "login"), allow_other_host: true
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :role])
  end
end
