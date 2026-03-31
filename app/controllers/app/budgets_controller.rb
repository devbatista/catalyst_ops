class App::BudgetsController < ApplicationController
  before_action :ensure_budget_access!
  before_action :authorize_budget_access!

  def index
    @clients = clients_scope.order(:name)
    @budgets = filtered_budgets
      .includes(:client, :users)
      .order(created_at: :desc)
      .page(params[:page])
      .per((params[:per] || 10).to_i)
  end

  private

  def ensure_budget_access!
    return if current_user.admin? || current_user.gestor?

    redirect_to app_order_services_path, alert: "Você não tem permissão para acessar a gestão de orçamentos."
  end

  def authorize_budget_access!
    authorize! :read, OrderService
  end

  def base_scope
    scope = current_user.admin? ? OrderService.all : current_user.company.order_services
    scope.where(status: [:rascunho, :rejeitada])
  end

  def clients_scope
    current_user.admin? ? Client.all : current_user.company.clients
  end

  def filtered_budgets
    scope = base_scope

    if params[:q].present?
      term = "%#{params[:q].strip}%"
      scope = scope.left_joins(:client).where(
        "order_services.title ILIKE :term OR order_services.description ILIKE :term OR clients.name ILIKE :term",
        term: term
      )
    end

    scope = scope.where(client_id: params[:client_id]) if params[:client_id].present?

    case params[:approval_state]
    when "nao_enviado"
      scope = scope.where(approval_sent_at: nil)
    when "enviado"
      scope = scope.where.not(approval_sent_at: nil).where(status: :rascunho)
    when "rejeitado"
      scope = scope.where(status: :rejeitada)
    end

    scope
  end
end
