class Admin::MetricsController < AdminController
  PERIODS = {
    "24h" => 24.hours,
    "7d" => 7.days,
    "30d" => 30.days
  }.freeze

  def index
    @selected_period_key = selected_period_key
    @period_start = Time.current - PERIODS.fetch(@selected_period_key)
    @period_end = Time.current
    @last_refreshed_at = Time.current
    @period_options = PERIODS.keys
    @sentry_status = sentry_status
    @error_indicators = error_indicators
    @sidekiq_indicators = sidekiq_indicators
    @onboarding_indicators = onboarding_indicators
    @quick_links = quick_links
  end

  def test_sentry
    unless sentry_status[:enabled] && defined?(Sentry)
      redirect_to admin_metrics_path(period: selected_period_key), alert: "Sentry não está configurado para este ambiente."
      return
    end

    begin
      error = RuntimeError.new("Teste manual de monitoramento (Admin > Métricas)")
      Sentry.capture_exception(error)

      Audit::Log.call(
        action: "system.monitoring.test_triggered",
        metadata: {
          event: "sentry_test_triggered",
          area: "admin.metrics",
          result: "sent"
        }
      )

      redirect_to admin_metrics_path(period: selected_period_key), notice: "Evento de teste enviado ao Sentry."
    rescue StandardError => e
      Audit::Log.call(
        action: "system.monitoring.test_triggered",
        metadata: {
          event: "sentry_test_triggered",
          area: "admin.metrics",
          result: "failed",
          error_class: e.class.name,
          error_message: e.message
        }
      )
      redirect_to admin_metrics_path(period: selected_period_key), alert: "Falha ao enviar evento de teste: #{e.message}"
    end
  end

  private

  def sentry_status
    current_environment = ENV.fetch("SENTRY_ENVIRONMENT", Rails.env)
    enabled_environments = %w[production staging]

    {
      enabled: ENV["SENTRY_DSN"].present?,
      active_in_environment: ENV["SENTRY_DSN"].present? && enabled_environments.include?(current_environment),
      environment: current_environment,
      traces_sample_rate: ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.1"),
      project_url: ENV["SENTRY_PROJECT_URL"].to_s,
      release: ENV["SENTRY_RELEASE"].to_s,
      missing_required_vars: missing_required_sentry_vars
    }
  end

  def error_indicators
    {
      job_failed: audit_count("job.failed"),
      report_failed: audit_count("report.export.failed"),
      webhook_failed: audit_count("webhook.failed")
    }
  end

  def sidekiq_indicators
    require "sidekiq/api"

    {
      processes: Sidekiq::ProcessSet.new.size,
      queue_default: Sidekiq::Queue.new("default").size,
      retries: Sidekiq::RetrySet.new.size,
      dead: Sidekiq::DeadSet.new.size
    }
  rescue StandardError
    {
      processes: 0,
      queue_default: 0,
      retries: 0,
      dead: 0
    }
  end

  def quick_links
    [
      { label: "Logs de auditoria", path: admin_logs_path },
      { label: "Configurações", path: admin_configurations_path },
      { label: "Tickets", path: admin_tickets_path }
    ]
  end

  def onboarding_indicators
    cohort_users = onboarding_cohort_users
    cohort_count = cohort_users.size

    return {
      cohort_count: 0,
      completed_count: 0,
      completion_rate: 0.0,
      dismissed_count: 0,
      dismiss_rate: 0.0,
      first_os_24h_count: 0,
      first_os_24h_rate: 0.0,
      avg_time_to_first_os_hours: nil,
      retained_d7_count: 0,
      retained_d7_rate: 0.0
    } if cohort_count.zero?

    cohort_ids = cohort_users.map(&:id)
    progress_by_user_id = UserOnboardingProgress.where(user_id: cohort_ids).index_by(&:user_id)

    completed_count = progress_by_user_id.values.count { |progress| progress.finished_at.present? }
    dismissed_count = progress_by_user_id.values.count { |progress| progress.dismissed_at.present? }

    first_os_data = first_order_service_metrics_for(cohort_users)
    retained_d7_count = retained_d7_count_for(cohort_users)

    {
      cohort_count: cohort_count,
      completed_count: completed_count,
      completion_rate: percentage(completed_count, cohort_count),
      dismissed_count: dismissed_count,
      dismiss_rate: percentage(dismissed_count, cohort_count),
      first_os_24h_count: first_os_data[:within_24h_count],
      first_os_24h_rate: percentage(first_os_data[:within_24h_count], cohort_count),
      avg_time_to_first_os_hours: first_os_data[:avg_hours],
      retained_d7_count: retained_d7_count,
      retained_d7_rate: percentage(retained_d7_count, cohort_count)
    }
  end

  def onboarding_cohort_users
    User.where(role: [:admin, :gestor])
        .where.not(company_id: nil)
        .where(created_at: @period_start..@period_end)
        .select(:id, :company_id, :created_at)
  end

  def first_order_service_metrics_for(users)
    within_24h_count = 0
    total_hours = 0.0
    users_with_first_os = 0

    users.each do |user|
      first_os_at = OrderService.where(company_id: user.company_id)
                                .where("created_at >= ?", user.created_at)
                                .order(:created_at)
                                .limit(1)
                                .pick(:created_at)
      next unless first_os_at

      delta_hours = (first_os_at - user.created_at) / 1.hour
      users_with_first_os += 1
      total_hours += delta_hours
      within_24h_count += 1 if delta_hours <= 24.0
    end

    avg_hours = users_with_first_os.positive? ? (total_hours / users_with_first_os).round(2) : nil

    {
      within_24h_count: within_24h_count,
      avg_hours: avg_hours
    }
  end

  def retained_d7_count_for(users)
    user_ids = users.map(&:id).map(&:to_s)
    return 0 if user_ids.empty?

    min_start = users.map { |user| user.created_at + 7.days }.min
    max_end = users.map { |user| user.created_at + 8.days }.max

    events_by_actor = AuditEvent.where(actor_id: user_ids, occurred_at: min_start..max_end)
                                .pluck(:actor_id, :occurred_at)
                                .group_by(&:first)

    users.count do |user|
      day7_start = user.created_at + 7.days
      day7_end = user.created_at + 8.days
      actor_events = events_by_actor[user.id.to_s] || []

      actor_events.any? do |(_actor_id, occurred_at)|
        occurred_at >= day7_start && occurred_at < day7_end
      end
    end
  end

  def percentage(numerator, denominator)
    return 0.0 if denominator.to_i <= 0

    ((numerator.to_f / denominator.to_f) * 100.0).round(1)
  end

  def selected_period_key
    period = params[:period].to_s
    return period if PERIODS.key?(period)

    "24h"
  end

  def audit_count(action)
    AuditEvent.where(action: action).where(occurred_at: @period_start..@period_end).count
  end

  def missing_required_sentry_vars
    required = ["SENTRY_DSN"]
    required.reject { |key| ENV[key].present? }
  end
end
