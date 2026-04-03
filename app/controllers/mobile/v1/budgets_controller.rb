class Mobile::V1::BudgetsController < Mobile::V1::BaseController
  def index
    scope = current_mobile_user.company.budgets.includes(:client, :order_service)
    scope = scope.where(status: params[:status]) if valid_status_filter?

    page = [params[:page].to_i, 1].max
    per = params[:per].to_i
    per = 20 if per <= 0
    per = 100 if per > 100

    budgets = scope.order(created_at: :desc).page(page).per(per)

    render json: {
      data: budgets.map { |budget| budget_index_payload(budget) },
      meta: {
        current_page: budgets.current_page,
        total_pages: budgets.total_pages,
        total_count: budgets.total_count,
        per_page: budgets.limit_value
      }
    }, status: :ok
  end

  def show
    budget = current_mobile_user.company.budgets
                      .includes(:client, :order_service, :service_items)
                      .find(params[:id])

    render json: { data: budget_show_payload(budget) }, status: :ok
  end

  private

  def valid_status_filter?
    params[:status].present? && Budget.statuses.key?(params[:status].to_s)
  end

  def budget_index_payload(budget)
    {
      id: budget.id,
      code: budget.code,
      title: budget.title,
      status: budget.status,
      client_name: budget.client&.name,
      valid_until: budget.valid_until&.iso8601,
      approval_expires_at: budget.approval_expires_at&.iso8601,
      total_value: budget.total_value.to_s
    }
  end

  def budget_show_payload(budget)
    {
      id: budget.id,
      code: budget.code,
      title: budget.title,
      description: budget.description,
      status: budget.status,
      valid_until: budget.valid_until&.iso8601,
      approval_expires_at: budget.approval_expires_at&.iso8601,
      approval_sent_at: budget.approval_sent_at&.iso8601,
      approved_at: budget.approved_at&.iso8601,
      rejected_at: budget.rejected_at&.iso8601,
      rejection_reason: budget.rejection_reason,
      estimated_delivery_days: budget.estimated_delivery_days,
      total_value: budget.total_value.to_s,
      client: {
        id: budget.client_id,
        name: budget.client&.name
      },
      order_service: {
        id: budget.order_service_id,
        code: budget.order_service&.code
      },
      service_items: budget.service_items.order(:created_at).map do |item|
        {
          id: item.id,
          description: item.description,
          quantity: item.quantity,
          unit_price: item.unit_price.to_s,
          total_price: (item.quantity.to_d * item.unit_price.to_d).to_s
        }
      end
    }
  end
end
