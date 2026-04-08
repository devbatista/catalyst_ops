class App::ReportsController < ApplicationController
  load_and_authorize_resource

  MAX_REPORT_PERIOD = 6.months

  REPORT_SOURCES = %w[order_services budgets].freeze
  GROUP_BY_OPTIONS = %w[day week month].freeze

  COMPLETED_STATUSES = %w[finalizada].freeze
  OPEN_STATUSES = %w[pendente agendada em_andamento atrasada concluida].freeze
  CANCELED_STATUSES = %w[cancelada].freeze

  BUDGET_APPROVED_STATUSES = %w[aprovado].freeze
  BUDGET_OPEN_STATUSES = %w[rascunho enviado].freeze
  BUDGET_REJECTED_STATUSES = %w[rejeitado cancelado].freeze
  
  def index
    @reports = @reports.order(created_at: :desc)
    @generated_reports = @reports.limit(5)

    @report_source = REPORT_SOURCES.include?(params[:report_source]) ? params[:report_source] : "order_services"
    @group_by = GROUP_BY_OPTIONS.include?(params[:group_by]) ? params[:group_by] : "day"

    @status_options = @report_source == "budgets" ? Budget.statuses.keys : OrderService.statuses.keys
    @technician_options = available_technicians

    @end_date = parse_report_date(params[:end_date]) || Date.current
    @start_date = parse_report_date(params[:start_date]) || (@end_date - 29.days)
    @start_date, @end_date = [@start_date, @end_date].minmax
    enforce_max_period!

    if @report_source == "budgets"
      build_budgets_report
    else
      build_order_services_report
    end
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

  def build_order_services_report
    created_scope = filtered_order_services_scope(date_column: :created_at)
    finished_scope = completed_order_services_scope_for_period
    canceled_scope = canceled_order_services_scope_for_period

    @report_summary = build_order_services_summary(
      created_scope: created_scope,
      finished_scope: finished_scope
    )
    @total_orders_count = @report_summary[:total_orders_count]
    @completed_orders_count = @report_summary[:completed_orders_count]
    @open_orders_count = @report_summary[:open_orders_count]
    @canceled_orders_count = @report_summary[:canceled_orders_count]
    @average_resolution_hours = @report_summary[:average_resolution_hours]
    @sla_rate = @report_summary[:sla_rate]
    @sla_on_time_orders_count = @report_summary[:sla_on_time_orders_count]
    @sla_eligible_orders_count = @report_summary[:sla_eligible_orders_count]

    build_trend_chart_data(
      total_scope: created_scope,
      total_date_expression: "order_services.created_at",
      success_scope: finished_scope,
      success_date_expression: "COALESCE(order_services.finished_at, order_services.updated_at)",
      primary_label: "OS criadas",
      secondary_label: "OS finalizadas",
      tertiary_scope: canceled_scope,
      tertiary_date_expression: "order_services.updated_at",
      tertiary_label: "OS canceladas",
      title: "Evolução operacional"
    )
    build_status_chart_data(created_scope)

    @report_orders = created_scope
      .includes(:client, :users)
      .order(created_at: :desc)
      .page(params[:page])
      .per(params[:per] || 10)
  end

  def build_budgets_report
    filtered_scope = filtered_budgets_scope

    @report_summary = build_budgets_summary(filtered_scope)
    @total_budgets_count = @report_summary[:total_budgets_count]
    @approved_budgets_count = @report_summary[:approved_budgets_count]
    @open_budgets_count = @report_summary[:open_budgets_count]
    @rejected_budgets_count = @report_summary[:rejected_budgets_count]
    @approval_rate = @report_summary[:approval_rate]
    @approval_eligible_budgets_count = @report_summary[:approval_eligible_budgets_count]
    @average_budget_value = @report_summary[:average_budget_value]

    build_trend_chart_data(
      total_scope: filtered_scope,
      total_date_expression: "budgets.created_at",
      success_scope: filtered_scope.where(status: BUDGET_APPROVED_STATUSES),
      success_date_expression: "budgets.created_at",
      primary_label: "Orçamentos criados",
      secondary_label: "Orçamentos aprovados",
      title: "Evolução comercial"
    )
    build_status_chart_data(filtered_scope)

    @report_budgets = filtered_scope
      .includes(:client)
      .order(created_at: :desc)
      .page(params[:page])
      .per(params[:per] || 10)
  end

  def base_order_services_scope
    if current_user.admin?
      OrderService.all
    else
      current_user.company.order_services
    end
  end

  def filtered_order_services_scope(date_column: :created_at)
    scope = base_order_services_scope
      .where(date_column => @start_date.beginning_of_day..@end_date.end_of_day)

    if params[:status].present? && @status_options.include?(params[:status])
      scope = scope.where(status: params[:status])
    end

    selected_technician_id = params[:technician_id].to_s
    if selected_technician_id.present? && technician_filter_ids.include?(selected_technician_id)
      scope = scope.joins(:users).where(users: { id: selected_technician_id })
    end

    scope.distinct
  end

  def completed_order_services_scope_for_period
    scope = base_order_services_scope.where(status: COMPLETED_STATUSES)

    if params[:status].present? && @status_options.include?(params[:status])
      scope = scope.where(status: params[:status])
    end

    selected_technician_id = params[:technician_id].to_s
    if selected_technician_id.present? && technician_filter_ids.include?(selected_technician_id)
      scope = scope.joins(:users).where(users: { id: selected_technician_id })
    end

    scope = scope.where(
      "COALESCE(order_services.finished_at, order_services.updated_at) BETWEEN ? AND ?",
      @start_date.beginning_of_day,
      @end_date.end_of_day
    )

    scope.distinct
  end

  def canceled_order_services_scope_for_period
    scope = base_order_services_scope.where(status: CANCELED_STATUSES)

    if params[:status].present? && @status_options.include?(params[:status])
      scope = scope.where(status: params[:status])
    end

    selected_technician_id = params[:technician_id].to_s
    if selected_technician_id.present? && technician_filter_ids.include?(selected_technician_id)
      scope = scope.joins(:users).where(users: { id: selected_technician_id })
    end

    scope = scope.where(updated_at: @start_date.beginning_of_day..@end_date.end_of_day)
    scope.distinct
  end

  def base_budgets_scope
    if current_user.admin?
      Budget.all
    else
      current_user.company.budgets
    end
  end

  def filtered_budgets_scope
    scope = base_budgets_scope.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)

    if params[:status].present? && @status_options.include?(params[:status])
      scope = scope.where(status: params[:status])
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
    @technician_filter_ids ||= @technician_options.pluck(:id).map(&:to_s)
  end

  def average_resolution_hours(scope)
    durations = scope
      .where(status: COMPLETED_STATUSES)
      .where.not(started_at: nil, finished_at: nil)
      .pluck(:started_at, :finished_at)
      .map { |started_at, finished_at| ((finished_at - started_at) / 1.hour).round(2) }

    return 0.0 if durations.empty?

    (durations.sum / durations.size).round(2)
  end

  def sla_details_for(scope)
    completed_scope = scope
      .where(status: COMPLETED_STATUSES)
      .where.not(expected_end_at: nil, finished_at: nil)

    total = completed_scope.distinct.count(:id)
    return { rate: 0.0, on_time_orders_count: 0, eligible_orders_count: 0 } if total.zero?

    on_time = completed_scope.where("finished_at <= expected_end_at").distinct.count(:id)
    {
      rate: ((on_time.to_f / total) * 100).round(1),
      on_time_orders_count: on_time,
      eligible_orders_count: total
    }
  end

  def build_order_services_summary(created_scope:, finished_scope:)
    total_orders_count = created_scope.distinct.count(:id)
    completed_orders_count = finished_scope.distinct.count(:id)
    open_orders_count = created_scope.where(status: OPEN_STATUSES).distinct.count(:id)
    canceled_orders_count = created_scope.where(status: CANCELED_STATUSES).distinct.count(:id)

    sla = sla_details_for(finished_scope)

    {
      total_orders_count: total_orders_count,
      completed_orders_count: completed_orders_count,
      open_orders_count: open_orders_count,
      canceled_orders_count: canceled_orders_count,
      average_resolution_hours: average_resolution_hours(finished_scope),
      sla_rate: sla[:rate],
      sla_on_time_orders_count: sla[:on_time_orders_count],
      sla_eligible_orders_count: sla[:eligible_orders_count]
    }
  end

  def build_budgets_summary(scope)
    total_budgets_count = scope.distinct.count(:id)
    approved_budgets_count = scope.where(status: BUDGET_APPROVED_STATUSES).distinct.count(:id)
    open_budgets_count = scope.where(status: BUDGET_OPEN_STATUSES).distinct.count(:id)
    rejected_budgets_count = scope.where(status: BUDGET_REJECTED_STATUSES).distinct.count(:id)

    approval_eligible = approved_budgets_count + rejected_budgets_count
    approval_rate = approval_eligible.zero? ? 0.0 : ((approved_budgets_count.to_f / approval_eligible) * 100).round(1)
    average_budget_value = scope.average(:total_value).to_f.round(2)

    {
      total_budgets_count: total_budgets_count,
      approved_budgets_count: approved_budgets_count,
      open_budgets_count: open_budgets_count,
      rejected_budgets_count: rejected_budgets_count,
      approval_rate: approval_rate,
      approval_eligible_budgets_count: approval_eligible,
      average_budget_value: average_budget_value
    }
  end

  def build_trend_chart_data(total_scope:, total_date_expression:, success_scope:, success_date_expression:, primary_label:, secondary_label:, title:, tertiary_scope: nil, tertiary_date_expression: nil, tertiary_label: nil)
    grouped_total = total_scope.group(Arel.sql(group_expression(total_date_expression))).count
    grouped_success = success_scope.group(Arel.sql(group_expression(success_date_expression))).count

    normalized_total = grouped_total.each_with_object({}) do |(key, value), hash|
      hash[normalize_group_key_from_db(key)] = value
    end
    normalized_success = grouped_success.each_with_object({}) do |(key, value), hash|
      hash[normalize_group_key_from_db(key)] = value
    end
    normalized_tertiary = if tertiary_scope.present? && tertiary_date_expression.present?
      grouped_tertiary = tertiary_scope.group(Arel.sql(group_expression(tertiary_date_expression))).count
      grouped_tertiary.each_with_object({}) do |(key, value), hash|
        hash[normalize_group_key_from_db(key)] = value
      end
    else
      {}
    end

    period = grouped_period

    @trend_chart_title = title
    @trend_primary_label = primary_label
    @trend_secondary_label = secondary_label
    @trend_tertiary_label = tertiary_label
    @trend_chart_labels = period.map { |period_start| period_label(period_start) }
    @trend_primary_values = period.map do |period_start|
      normalized_total[normalized_group_key(period_start)] || 0
    end
    @trend_secondary_values = period.map do |period_start|
      normalized_success[normalized_group_key(period_start)] || 0
    end
    @trend_tertiary_values = period.map do |period_start|
      normalized_tertiary[normalized_group_key(period_start)] || 0
    end
  end

  def grouped_period
    case @group_by
    when "week"
      start_date = @start_date.beginning_of_week
      end_date = @end_date.beginning_of_week
      (start_date..end_date).step(7).to_a
    when "month"
      start_date = @start_date.beginning_of_month
      end_date = @end_date.beginning_of_month

      period = []
      cursor = start_date
      while cursor <= end_date
        period << cursor
        cursor = cursor.next_month
      end
      period
    else
      (@start_date..@end_date).to_a
    end
  end

  def group_expression(date_expression)
    case @group_by
    when "week"
      "DATE_TRUNC('week', #{date_expression})"
    when "month"
      "DATE_TRUNC('month', #{date_expression})"
    else
      "DATE(#{date_expression})"
    end
  end

  def normalized_group_key(period_start)
    case @group_by
    when "week"
      period_start.to_date.beginning_of_week
    when "month"
      period_start.to_date.beginning_of_month
    else
      period_start.to_date
    end
  end

  def normalize_group_key_from_db(key)
    case @group_by
    when "week"
      key.to_date.beginning_of_week
    when "month"
      key.to_date.beginning_of_month
    else
      key.to_date
    end
  end

  def period_label(period_start)
    case @group_by
    when "week"
      "Sem #{I18n.l(period_start.to_date, format: '%d/%m')}"
    when "month"
      I18n.l(period_start.to_date, format: "%m/%Y")
    else
      I18n.l(period_start.to_date, format: "%d/%m")
    end
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

  def enforce_max_period!
    max_start_date = (@end_date.to_time - MAX_REPORT_PERIOD).to_date
    return unless @start_date < max_start_date

    @start_date = max_start_date
    flash.now[:alert] = "O período máximo permitido é de 6 meses. Ajustamos a data inicial para #{I18n.l(@start_date)}."
  end
end
