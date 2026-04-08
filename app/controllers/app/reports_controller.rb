class App::ReportsController < ApplicationController
  load_and_authorize_resource
  
  def index
    @reports = @reports.order(created_at: :desc)
    @generated_reports = @reports.limit(5)

    @status_options = OrderService.statuses.keys
    @technician_options = available_technicians

    @end_date = parse_report_date(params[:end_date]) || Date.current
    @start_date = parse_report_date(params[:start_date]) || (@end_date - 29.days)
    @start_date, @end_date = [@start_date, @end_date].minmax

    filtered_scope = filtered_order_services_scope

    @total_orders_count = filtered_scope.distinct.count(:id)
    @completed_orders_count = filtered_scope.where(status: [:concluida, :finalizada]).distinct.count(:id)
    @pending_orders_count = @total_orders_count - @completed_orders_count
    @average_resolution_hours = average_resolution_hours(filtered_scope)
    @sla_rate = sla_rate_for(filtered_scope)

    build_volume_chart_data(filtered_scope)
    build_status_chart_data(filtered_scope)

    @report_orders = filtered_scope
      .includes(:client, :users)
      .order(created_at: :desc)
      .page(params[:page])
      .per(params[:per] || 10)
  end

  def show
    redirect_to @report.file.url, allow_other_host: true
  end

  def service_orders
    authorize! :read, ServiceOrder

    @service_orders = current_company.service_orders

    if params[:start_date].present? && params[:end_date].present?
      @start_date = Date.parse(params[:start_date])
      @end_date = Date.parse(params[:end_date])
      @service_orders = @service_orders.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
    end

    if params[:status].present?
      @status = params[:status]
      @service_orders = @service_orders.where(status: @status)
    end

    @service_orders = @service_orders.none unless request.post?
  end

  private

  def base_order_services_scope
    if current_user.admin?
      OrderService.all
    else
      current_user.company.order_services
    end
  end

  def filtered_order_services_scope
    scope = base_order_services_scope
      .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)

    if params[:status].present? && @status_options.include?(params[:status])
      scope = scope.where(status: params[:status])
    end

    if params[:technician_id].present? && technician_filter_ids.include?(params[:technician_id].to_i)
      scope = scope.joins(:users).where(users: { id: params[:technician_id].to_i })
    end

    scope.distinct
  end

  def available_technicians
    if current_user.admin?
      User.active.tecnicos.order(:name)
    else
      current_user.company.users.active.tecnicos.order(:name)
    end
  end

  def technician_filter_ids
    @technician_filter_ids ||= @technician_options.pluck(:id)
  end

  def average_resolution_hours(scope)
    durations = scope
      .where(status: [:concluida, :finalizada])
      .where.not(started_at: nil, finished_at: nil)
      .pluck(:started_at, :finished_at)
      .map { |started_at, finished_at| ((finished_at - started_at) / 1.hour).round(2) }

    return 0.0 if durations.empty?

    (durations.sum / durations.size).round(2)
  end

  def sla_rate_for(scope)
    completed_scope = scope
      .where(status: [:concluida, :finalizada])
      .where.not(expected_end_at: nil, finished_at: nil)

    total = completed_scope.distinct.count(:id)
    return 0.0 if total.zero?

    on_time = completed_scope.where("finished_at <= expected_end_at").distinct.count(:id)
    ((on_time.to_f / total) * 100).round(1)
  end

  def build_volume_chart_data(scope)
    daily_counts = scope.group("DATE(order_services.created_at)").count
    period = (@start_date..@end_date).to_a

    @volume_chart_labels = period.map { |date| I18n.l(date, format: "%d/%m") }
    @volume_chart_values = period.map { |date| daily_counts[date] || 0 }
  end

  def build_status_chart_data(scope)
    grouped = scope.group(:status).count
    ordered_statuses = OrderService.statuses.keys.select { |status| grouped.key?(status) }

    @status_chart_labels = ordered_statuses.map(&:humanize)
    @status_chart_values = ordered_statuses.map { |status| grouped[status] }
    @status_chart_colors = ordered_statuses.map { |status| status_color_hex(status) }
  end

  def status_color_hex(status)
    {
      "pendente" => "#6c757d",
      "agendada" => "#ffc107",
      "em_andamento" => "#0dcaf0",
      "concluida" => "#198754",
      "finalizada" => "#0d6efd",
      "cancelada" => "#dc3545",
      "atrasada" => "#343a40"
    }[status] || "#6c757d"
  end

  def parse_report_date(raw_date)
    return if raw_date.blank?

    Date.parse(raw_date)
  rescue ArgumentError
    nil
  end
end
