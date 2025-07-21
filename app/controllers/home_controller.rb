class HomeController < ApplicationController
  def index
    authorize! :read, :home
    
    case current_user.role
    when 'admin'
      redirect_to admin_dashboard_path if respond_to?(:admin_dashboard_path)
    when 'gestor'
      redirect_to gestor_dashboard_path if respond_to?(:gestor_dashboard_path)
    when 'tecnico'
      redirect_to tecnico_dashboard_path if respond_to?(:tecnico_dashboard_path)
    end
  end
end