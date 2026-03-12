class AdminController < ApplicationController
  layout "admin"
  
  skip_authorization_check
  before_action :require_admin

  private
  
  def require_admin
    unless current_user&.admin?
      redirect_to login_root_url(subdomain: "login"),
                                 alert: "Acesso negado.",
                                 allow_other_host: true
    end
  end
end