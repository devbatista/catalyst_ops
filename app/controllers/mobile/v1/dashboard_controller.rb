class Mobile::V1::DashboardController < Mobile::V1::BaseController
  def show
    scope = mobile_order_services_scope.includes(:client, :users)

    mobile_audit(
      action: "mobile.api.dashboard.viewed",
      metadata: { user_id: current_mobile_user.id }
    )

    render json: {
      metrics: dashboard_metrics(scope),
      upcomingVisits: upcoming_visits(scope),
      statusBreakdown: status_breakdown(scope),
      recentOrders: recent_orders(scope)
    }, status: :ok
  end

  private

  def dashboard_metrics(scope)
    open_statuses = %i[pendente agendada em_andamento atrasada]

    [
      {
        key: "open_orders",
        title: "OS abertas",
        value: scope.where(status: open_statuses).count.to_s,
        subtitle: "Em andamento, pendentes, atrasadas ou agendadas"
      },
      {
        key: "today_orders",
        title: "Visitas hoje",
        value: scope.where(scheduled_at: Time.zone.today.all_day).count.to_s,
        subtitle: "Agendadas para hoje"
      },
      {
        key: "overdue_orders",
        title: "Atrasadas",
        value: scope.where(status: :atrasada).count.to_s,
        subtitle: "Precisam de atenção"
      },
      {
        key: "completed_orders",
        title: "Concluídas",
        value: scope.where(status: %i[concluida finalizada]).count.to_s,
        subtitle: "Atendimentos concluídos"
      }
    ]
  end

  def upcoming_visits(scope)
    scope.where.not(scheduled_at: nil)
         .where("scheduled_at >= ?", Time.current.beginning_of_day)
         .order(:scheduled_at)
         .limit(5)
         .map do |order_service|
      {
        id: order_service.id,
        code: mobile_order_code(order_service),
        client: order_service.client&.name,
        schedule: schedule_label(order_service.scheduled_at),
        scheduledAt: iso8601(order_service.scheduled_at),
        status: mobile_status_key(order_service.status),
        statusLabel: mobile_status_label(order_service.status)
      }
    end
  end

  def status_breakdown(scope)
    scope.group(:status).count.map do |status, count|
      {
        status: mobile_status_key(status),
        label: mobile_status_label(status),
        count: count
      }
    end
  end

  def recent_orders(scope)
    scope.order(created_at: :desc)
         .limit(5)
         .map { |order_service| mobile_order_service_payload(order_service, detailed: false) }
  end

  def schedule_label(datetime)
    return nil if datetime.blank?

    date_label =
      if datetime.to_date == Time.zone.today
        "Hoje"
      elsif datetime.to_date == Time.zone.tomorrow
        "Amanhã"
      else
        I18n.l(datetime.to_date, format: :short)
      end

    "#{date_label}, #{datetime.strftime('%H:%M')}"
  end
end
