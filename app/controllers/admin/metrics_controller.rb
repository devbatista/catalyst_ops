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
