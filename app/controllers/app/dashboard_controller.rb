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
      # --- Coleções Base ---
      @order_services = current_user.company.order_services
      company_clients = current_user.company.clients
      company_technicians = User.where(role: :tecnico, company_id: current_user.company_id)

      # --- KPIs Principais (já existentes) ---
      @clients_count = company_clients.count
      @technicians_count = company_technicians.count
      @order_services_by_status = @order_services.group(:status).count
      @recent_orders = @order_services.order(created_at: :desc).limit(6)
      # KPI de faturamento total para o card principal
      @total_revenue = @order_services.joins(:service_items).sum('service_items.unit_price')

      # --- NOVOS CÁLCULOS PARA VARIAÇÃO SEMANAL ---

      # 1. Variação de Ordens de Serviço Criadas
      @orders_current_week = @order_services.where(created_at: Time.now.all_week).count
      @orders_last_week = @order_services.where(created_at: 1.week.ago.all_week).count

      # 2. Variação de Faturamento (de OS concluídas na semana)
      finished_orders = @order_services.where(status: :finished)
      @revenue_current_week = finished_orders.where(updated_at: Time.now.all_week)
                                             .joins(:service_items).sum('service_items.unit_price')
      @revenue_last_week = finished_orders.where(updated_at: 1.week.ago.all_week)
                                          .joins(:service_items).sum('service_items.unit_price')

      # 3. Variação de Novos Técnicos
      @new_technicians_current_week = company_technicians.where(created_at: Time.now.all_week).count
      @new_technicians_last_week = company_technicians.where(created_at: 1.week.ago.all_week).count

      # 4. Variação de Novos Clientes
      @new_clients_current_week = company_clients.where(created_at: Time.now.all_week).count
      @new_clients_last_week = company_clients.where(created_at: 1.week.ago.all_week).count

      # 5. Query para ações pendentes
      @pending_approval_orders = @order_services.concluida.order(created_at: :asc).limit(6)

    when "tecnico"
      @order_services = current_user.order_services
      @order_services_by_status = @order_services.group(:status).count
      @recent_orders = @order_services.order(created_at: :desc).limit(6)
      @my_orders = current_user.order_services.includes(:client)
      @pending_orders = @my_orders.agendada.count
      @in_progress_orders = @my_orders.em_andamento.count
    end
  end
end
