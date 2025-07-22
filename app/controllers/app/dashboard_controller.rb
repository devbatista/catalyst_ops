class App::DashboardController < ApplicationController
  def index
    authorize! :read, :dashboard
    
    case current_user.role
    when 'admin', 'gestor'
      @clients_count = Client.count
      @order_services_count = OrderService.count
      @pending_orders = OrderService.agendada.count
      @in_progress_orders = OrderService.em_andamento.count
      @recent_orders = OrderService.includes(:client).order(created_at: :desc).limit(5)
    when 'tecnico'
      @my_orders = current_user.order_services.includes(:client)
      @pending_orders = @my_orders.agendada.count
      @in_progress_orders = @my_orders.em_andamento.count
    end
  end
end