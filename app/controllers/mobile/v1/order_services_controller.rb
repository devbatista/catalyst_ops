class Mobile::V1::OrderServicesController < Mobile::V1::BaseController
  def index
    scope = current_mobile_user.company.order_services.includes(:client, :users)
    scope = scope.where(status: params[:status]) if valid_status_filter?

    page = [params[:page].to_i, 1].max
    per = params[:per].to_i
    per = 20 if per <= 0
    per = 100 if per > 100

    order_services = scope.order(created_at: :desc).page(page).per(per)

    render json: {
      data: order_services.map { |os| order_service_index_payload(os) },
      meta: {
        current_page: order_services.current_page,
        total_pages: order_services.total_pages,
        total_count: order_services.total_count,
        per_page: order_services.limit_value
      }
    }, status: :ok
  end

  def show
    order_service = current_mobile_user.company.order_services
                               .includes(:client, :users, :service_items)
                               .find(params[:id])

    render json: { data: order_service_show_payload(order_service) }, status: :ok
  end

  private

  def valid_status_filter?
    params[:status].present? && OrderService.statuses.key?(params[:status].to_s)
  end

  def order_service_index_payload(order_service)
    {
      id: order_service.id,
      code: order_service.code,
      title: order_service.title,
      status: order_service.status,
      client_name: order_service.client&.name,
      technicians: order_service.users.map(&:name),
      scheduled_at: order_service.scheduled_at&.iso8601,
      expected_end_at: order_service.expected_end_at&.iso8601,
      total_value: order_service.total_value.to_s
    }
  end

  def order_service_show_payload(order_service)
    {
      id: order_service.id,
      code: order_service.code,
      title: order_service.title,
      description: order_service.description,
      status: order_service.status,
      observations: order_service.observations,
      rejection_reason: order_service.rejection_reason,
      scheduled_at: order_service.scheduled_at&.iso8601,
      expected_end_at: order_service.expected_end_at&.iso8601,
      started_at: order_service.started_at&.iso8601,
      finished_at: order_service.finished_at&.iso8601,
      client: {
        id: order_service.client_id,
        name: order_service.client&.name
      },
      technicians: order_service.users.map { |user| { id: user.id, name: user.name } },
      financial: {
        subtotal_value: order_service.subtotal_value.to_s,
        discount_type: order_service.discount_type,
        discount_value: order_service.discount_value.to_s,
        discount_amount: order_service.discount_amount.to_s,
        total_value: order_service.total_value.to_s
      },
      service_items: order_service.service_items.order(:created_at).map do |item|
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
