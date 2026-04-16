class App::DashboardController < ApplicationController
  def index
    authorize! :read, :dashboard

    initialize_default_dashboard_variables
    set_onboarding_welcome_modal

    case current_user.role
    when "admin"
      @clients_count = Client.count
      @order_services_count = OrderService.count
      @pending_orders = OrderService.agendada.count
      @in_progress_orders = OrderService.em_andamento.count
      @recent_orders = OrderService.includes(:client).order(created_at: :desc).limit(5)
    when "gestor"
      # --- Coleções Base ---
      company = current_user.company
      @order_services = company.order_services
      @budgets = company.budgets
      company_clients = company.clients
      company_technicians = company.technicians

      # --- KPIs Principais (já existentes) ---
      @clients_count = company_clients.count
      @technicians_count = company_technicians.count
      @order_services_by_status = @order_services.group(:status).count
      @recent_orders = @order_services.order(created_at: :desc).limit(6)
      @budgets_by_status = @budgets.group(:status).count
      @recent_budgets = @budgets.includes(:client).order(created_at: :desc).limit(6)
      # KPI de faturamento total para o card principal
      @total_revenue = sum_order_services_items(@order_services)
      @budgets_total_value = @budgets.sum(:total_value)

      # --- NOVOS CÁLCULOS PARA VARIAÇÃO SEMANAL ---

      # 1. Variação de Ordens de Serviço Criadas
      @orders_current_week = @order_services.where(created_at: Time.now.all_week).count
      @orders_last_week = @order_services.where(created_at: 1.week.ago.all_week).count

      # 2. Variação de Faturamento (de OS concluídas na semana)
      finished_orders = @order_services.where(status: :finalizada)
      @revenue_current_week = sum_order_services_items(finished_orders.where(updated_at: Time.now.all_week))
      @revenue_last_week = sum_order_services_items(finished_orders.where(updated_at: 1.week.ago.all_week))

      # 3. Variação de Novos Técnicos
      @new_technicians_current_week = company_technicians.where(created_at: Time.now.all_week).count
      @new_technicians_last_week = company_technicians.where(created_at: 1.week.ago.all_week).count

      # 4. Variação de Novos Clientes
      @new_clients_current_week = company_clients.where(created_at: Time.now.all_week).count
      @new_clients_last_week = company_clients.where(created_at: 1.week.ago.all_week).count

      # 5. Variação de novos Orçamentos
      @new_budgets_current_week = @budgets.where(created_at: Time.now.all_week).count
      @new_budgets_last_week = @budgets.where(created_at: 1.week.ago.all_week).count

      # 6. Query para ações pendentes
      @pending_approval_orders = @order_services.concluida.order(created_at: :asc).limit(6)
      @pending_approval_budgets = @budgets.enviado.order(approval_sent_at: :asc, created_at: :asc).limit(6)
    when "tecnico"
      load_technician_dashboard
    end
  end

  private

  def sum_order_services_items(scope)
    scope.joins(:service_items).sum("COALESCE(service_items.quantity, 0) * COALESCE(service_items.unit_price, 0)")
  end

  def load_technician_dashboard
    @order_services = current_user.order_services.includes(:client, :users, :service_items)
    @order_services_by_status = @order_services.group(:status).count

    @today_schedule = @order_services
      .where(status: [:agendada, :em_andamento, :concluida, :finalizada, :atrasada])
      .where(scheduled_at: Time.current.all_day)
      .order(:scheduled_at)

    @today_schedule_count = @today_schedule.count
    @in_progress_count = @order_services.em_andamento.count
    @overdue_count = @order_services.atrasada.count
    @completed_this_month_count = @order_services
      .where(status: [:concluida, :finalizada])
      .where("finished_at >= ?", Time.current.beginning_of_month)
      .count

    @upcoming_schedule = @order_services
      .agendada
      .where("scheduled_at >= ?", Time.current)
      .order(:scheduled_at)
      .limit(6)

    @current_assignments = @order_services
      .em_andamento
      .order(Arel.sql("COALESCE(order_services.started_at, order_services.updated_at) DESC"))
      .limit(6)

    @pending_approval_orders = @order_services
      .concluida
      .order(finished_at: :asc, updated_at: :asc)
      .limit(6)

    @recent_orders = @order_services
      .where(status: [:concluida, :finalizada])
      .order(Arel.sql("COALESCE(order_services.finished_at, order_services.updated_at) DESC"))
      .limit(6)
  end

  def initialize_default_dashboard_variables
    # Contadores numéricos
    @clients_count = 0
    @technicians_count = 0
    @order_services_count = 0
    @total_revenue = 0
    @completed_this_month_count = 0

    # Contadores para variação semanal
    @orders_current_week = 0
    @orders_last_week = 0
    @revenue_current_week = 0
    @revenue_last_week = 0
    @new_clients_current_week = 0
    @new_clients_last_week = 0
    @new_technicians_current_week = 0
    @new_technicians_last_week = 0
    @new_budgets_current_week = 0
    @new_budgets_last_week = 0

    # Coleções (Arrays/Hashes)
    @order_services_by_status = {}
    @budgets_by_status = {}
    @pending_approval_orders = []
    @pending_approval_budgets = []
    @recent_orders = []
    @recent_budgets = []
    @budgets = []
    @upcoming_schedule = []
    @current_assignments = []
    @today_schedule = []
    @today_schedule_count = 0
    @in_progress_count = 0
    @overdue_count = 0
    @budgets_total_value = 0
  end

  def set_onboarding_welcome_modal
    @onboarding_progress = current_user.user_onboarding_progress
    @show_onboarding_welcome_modal = onboarding_welcome_eligible?
    @show_onboarding_checklist = !current_user.tecnico?
    @onboarding_checklist_steps = onboarding_checklist_steps
  end

  def onboarding_welcome_eligible?
    return false if current_user.tecnico?
    return true if @onboarding_progress.nil?
    return false if @onboarding_progress.dismissed_at.present?
    return false if @onboarding_progress.finished_at.present?

    !@onboarding_progress.finished_all_steps?
  end

  def onboarding_checklist_steps
    [
      { key: "created_technician", label: "Cadastrar técnico", path: app_technicians_path },
      { key: "created_customer", label: "Cadastrar cliente", path: app_clients_path },
      { key: "created_budget", label: "Criar primeiro orçamento", path: app_budgets_path },
      { key: "created_first_work_order", label: "Aprovar orçamento para gerar a primeira OS", path: app_budgets_path },
      { key: "moved_work_order_status", label: "Atualizar status da ordem de serviço", path: app_order_services_path },
      { key: "viewed_reports", label: "Visualizar relatórios", path: app_reports_path }
    ]
  end
end
