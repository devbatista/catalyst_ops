class ApplicationJob < ActiveJob::Base
  rescue_from(StandardError) do |error|
    audit_failure(error)
    raise error
  end

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  private

  def audit_failure(error)
    Audit::Log.call(
      action: "job.failed",
      metadata: {
        event: "job_failed",
        job_name: self.class.name,
        queue_name: queue_name,
        job_id: job_id,
        arguments_preview: safe_arguments_preview,
        error_class: error.class.name,
        error_message: error.message
      }
    )
  rescue StandardError => audit_error
    Rails.logger.error("[ApplicationJob] Falha ao auditar erro do job #{self.class.name}: #{audit_error.message}")
  end

  def safe_arguments_preview
    Array(arguments).first(5).map do |arg|
      value = arg.inspect
      value.length > 200 ? "#{value[0, 200]}..." : value
    end
  end
end
