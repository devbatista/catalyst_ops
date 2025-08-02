class App::DashboardController < ApplicationController
  def index
    authorize! :read, :dashboard

    case current_user.role
    when "admin"
      @clients_count = Client.count
      @order_services_count = OrderService.count
      @pending_orders = OrderService.agendada.count
      @in_progress_orders = OrderService.em_andamento.count
      @recent_orders = OrderService.includes(:client).order(created_at: :desc).limit(5)
    when "gestor"
      @clients_count = current_user.clients.count
      @order_services = current_user.company.order_services
      @technicians_count = User.where(role: :tecnico, company_id: current_user.company_id).count
      @recent_orders = @order_services.order(created_at: :desc).limit(6)
    when "tecnico"
      @order_services = current_user.order_services
      @recent_orders = @order_services.order(created_at: :desc).limit(6)
      @my_orders = current_user.order_services.includes(:client)
      @pending_orders = @my_orders.agendada.count
      @in_progress_orders = @my_orders.em_andamento.count
    end
  end
end
