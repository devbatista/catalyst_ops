module Audit
  class JobLifecycleLogger
    def initialize(job_name:, jid:, metadata: {})
      @job_name = job_name
      @jid = jid
      @base_metadata = metadata
    end

    def started(event: "job_started")
      Audit::Log.call(
        action: "job.started",
        metadata: base_payload.merge(event: event)
      )
    end

    def completed(event: "job_completed", started_at:, extra: {})
      finished_at = Time.current
      Audit::Log.call(
        action: "job.completed",
        metadata: base_payload.merge(
          event: event,
          started_at: started_at,
          finished_at: finished_at,
          duration_ms: ((finished_at - started_at) * 1000).round
        ).merge(extra)
      )
    end

    def failed(error:, event: "job_failed", extra: {})
      Audit::Log.call(
        action: "job.failed",
        metadata: base_payload.merge(
          event: event,
          error_class: error.class.name,
          error_message: error.message
        ).merge(extra)
      )
    end

    private

    attr_reader :job_name, :jid, :base_metadata

    def base_payload
      {
        job_name: job_name,
        jid: jid
      }.merge(base_metadata)
    end
  end
end
