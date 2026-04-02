class App::BudgetsController < ApplicationController
  before_action :ensure_budget_access!
  before_action :authorize_budget_access!
  before_action :set_budget, only: [:show, :edit, :update, :send_for_approval, :approve, :reject, :generate_pdf]
  before_action :authorize_budget_management!, only: [:new, :create, :edit, :update, :send_for_approval, :approve, :reject, :generate_pdf]
  before_action :ensure_budget_editable!, only: [:edit, :update]

  def index
    @clients = clients_scope.order(:name)
    @budgets = filtered_budgets
      .includes(:client, :order_service)
      .order(created_at: :desc)
      .page(params[:page])
      .per((params[:per] || 10).to_i)
  end

  def new
    @budget = base_scope.new(client_id: params[:client_id])
    @budget.service_items.build if @budget.service_items.empty?
    @clients = clients_scope.order(:name)
  end

  def show; end

  def create
    @budget = base_scope.new(budget_params)

    if @budget.save
      redirect_to app_budgets_path, notice: "Orçamento criado com sucesso."
    else
      @budget.service_items.build if @budget.service_items.empty?
      @clients = clients_scope.order(:name)
      flash.now[:alert] = @budget.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @budget.service_items.build if @budget.service_items.empty?
    @clients = clients_scope.order(:name)
  end

  def update
    if @budget.update(update_budget_params)
      redirect_to app_budgets_path, notice: "Orçamento atualizado com sucesso."
    else
      @budget.service_items.build if @budget.service_items.empty?
      @clients = clients_scope.order(:name)
      flash.now[:alert] = @budget.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def send_for_approval
    unless @budget.rascunho? || @budget.rejeitado?
      return redirect_to app_budget_path(@budget), alert: "Apenas orçamentos em rascunho ou rejeitados podem ser enviados."
    end

    if @budget.approval_sent_at.present? && @budget.approval_sent_at > 5.minutes.ago
      return redirect_to app_budget_path(@budget), alert: "Aguarde alguns minutos antes de reenviar para aprovação."
    end

    @budget.send_for_approval!
    token = @budget.approval_token(expires_at: @budget.approval_expires_at)
    BudgetMailer.approval_request_to_client(@budget, token, sender_name: current_user.name).deliver_later

    redirect_to app_budget_path(@budget), notice: "Orçamento enviado para aprovação do cliente."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to app_budget_path(@budget), alert: e.record.errors.full_messages.to_sentence
  end

  def approve
    already_linked = @budget.order_service.present?
    @budget.approve_and_create_order_service!(approver_role: :gestor)
    notice = already_linked ? "Orçamento já aprovado. OS vinculada mantida como pendente." : "Orçamento aprovado pelo gestor e OS criada como pendente."
    redirect_to app_budget_path(@budget), notice: notice
  rescue ActiveRecord::RecordInvalid => e
    redirect_to app_budget_path(@budget), alert: e.record.errors.full_messages.to_sentence
  end

  def reject
    @budget.reject!(rejection_reason: params[:rejection_reason])
    redirect_to app_budget_path(@budget), notice: "Orçamento rejeitado pelo gestor."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to app_budget_path(@budget), alert: e.record.errors.full_messages.to_sentence
  end

  def generate_pdf
    pdf_data = Cmd::Pdf::CreateBudget.new(@budget).generate_pdf_data
    send_data pdf_data,
              filename: "orcamento_#{@budget.id}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

  private

  def ensure_budget_access!
    return if current_user.admin? || current_user.gestor?

    redirect_to app_order_services_path, alert: "Você não tem permissão para acessar a gestão de orçamentos."
  end

  def authorize_budget_access!
    authorize! :read, Budget
  end

  def set_budget
    @budget = base_scope.find(params[:id])
  end

  def authorize_budget_management!
    budget = @budget || Budget.new(company_id: current_user.company_id)
    authorize! :manage, budget
  end

  def ensure_budget_editable!
    return if @budget.editable?

    redirect_to app_budgets_path, alert: "Este orçamento não pode mais ser alterado."
  end

  def base_scope
    current_user.admin? ? Budget.all : current_user.company.budgets
  end

  def clients_scope
    current_user.admin? ? Client.all : current_user.company.clients
  end

  def filtered_budgets
    scope = base_scope

    if params[:q].present?
      term = "%#{params[:q].strip}%"
      scope = scope.left_joins(:client).where(
        "budgets.title ILIKE :term OR budgets.description ILIKE :term OR clients.name ILIKE :term",
        term: term
      )
    end

    scope = scope.where(client_id: params[:client_id]) if params[:client_id].present?

    case params[:approval_state]
    when "nao_enviado"
      scope = scope.where(approval_sent_at: nil).where(status: :rascunho)
    when "enviado"
      scope = scope.where(status: :enviado)
    when "rejeitado"
      scope = scope.where(status: :rejeitado)
    end

    scope
  end

  def budget_params
    params.require(:budget).permit(
      :title, :description, :client_id, :total_value, :valid_until, :estimated_delivery_days,
      service_items_attributes: [:id, :description, :quantity, :unit_price, :_destroy]
    )
  end

  def update_budget_params
    return budget_params unless @budget.rejeitado?

    budget_params.merge(
      status: :rascunho,
      rejected_at: nil,
      rejection_reason: nil,
      approved_at: nil,
      approval_sent_at: nil
    )
  end
end
