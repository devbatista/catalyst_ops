class Audit::CleanupEventsJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 2

  def perform
    started_at = Time.current
    job_audit.started(event: "audit_cleanup_started")

    result = Audit::CleanupOldEvents.new(
      retention_days: retention_days,
      batch_size: batch_size,
      dry_run: dry_run?
    ).call

    Rails.logger.info("[Audit::CleanupEventsJob] Limpeza de audit_events concluida: #{result}")

    job_audit.completed(
      event: "audit_cleanup_completed",
      started_at: started_at,
      extra: result
    )
  rescue StandardError => e
    job_audit.failed(
      event: "audit_cleanup_failed",
      error: e,
      extra: {
        retention_days: retention_days,
        batch_size: batch_size,
        dry_run: dry_run?
      }
    )
    raise
  end

  private

  def retention_days
    @retention_days ||= positive_or_default(ENV.fetch("AUDIT_LOG_RETENTION_DAYS", 180), 180)
  end

  def batch_size
    @batch_size ||= positive_or_default(ENV.fetch("AUDIT_LOG_CLEANUP_BATCH_SIZE", 1000), 1000)
  end

  def dry_run?
    @dry_run ||= ActiveModel::Type::Boolean.new.cast(ENV.fetch("AUDIT_LOG_CLEANUP_DRY_RUN", false))
  end

  def positive_or_default(value, fallback)
    parsed = value.to_i
    parsed.positive? ? parsed : fallback
  end

  def job_audit
    @job_audit ||= Audit::JobLifecycleLogger.new(
      job_name: self.class.name,
      jid: jid,
      metadata: {
        retention_days: retention_days,
        batch_size: batch_size,
        dry_run: dry_run?
      }
    )
  end
end
