class Mobile::V1::AgendaController < Mobile::V1::BaseController
  def index
    scope = mobile_order_services_scope.includes(:client, :users)
    scope = scope.where(scheduled_at: date_range)

    mobile_audit(
      action: "mobile.api.agenda.viewed",
      metadata: { start_date: start_date.iso8601, end_date: end_date.iso8601 }
    )

    render json: {
      data: scope.order(:scheduled_at).map { |order_service| agenda_payload(order_service) }
    }, status: :ok
  end

  private

  def agenda_payload(order_service)
    {
      id: order_service.id,
      code: mobile_order_code(order_service),
      title: order_service.title,
      client: order_service.client&.name,
      technician: order_service.users.first&.name,
      technicians: order_service.users.map(&:name),
      start: iso8601(order_service.scheduled_at),
      end: iso8601(order_service.expected_end_at),
      status: mobile_status_key(order_service.status),
      statusLabel: mobile_status_label(order_service.status),
      address: client_address(order_service.client)
    }
  end

  def date_range
    start_date.beginning_of_day..end_date.end_of_day
  end

  def start_date
    @start_date ||= parse_date(params[:start_date]) || Time.zone.today.beginning_of_month
  end

  def end_date
    @end_date ||= parse_date(params[:end_date]) || Time.zone.today.end_of_month
  end

  def parse_date(value)
    return if value.blank?

    Date.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end
end
