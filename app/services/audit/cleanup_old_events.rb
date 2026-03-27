module Audit
  class CleanupOldEvents
    DEFAULT_RETENTION_DAYS = 180
    DEFAULT_BATCH_SIZE = 1000

    def initialize(retention_days:, batch_size:, dry_run:)
      @retention_days = positive_or_default(retention_days, DEFAULT_RETENTION_DAYS)
      @batch_size = positive_or_default(batch_size, DEFAULT_BATCH_SIZE)
      @dry_run = dry_run
    end

    def call
      candidates = AuditEvent.where("occurred_at < ?", cutoff_time)
      total_candidates = candidates.count
      deleted_count = 0

      candidates.in_batches(of: batch_size) do |batch|
        affected_rows = dry_run ? batch.count : batch.delete_all
        deleted_count += affected_rows
      end

      {
        retention_days: retention_days,
        batch_size: batch_size,
        dry_run: dry_run,
        cutoff_time: cutoff_time.iso8601,
        total_candidates: total_candidates,
        deleted_count: deleted_count
      }
    end

    private

    attr_reader :retention_days, :batch_size, :dry_run

    def cutoff_time
      @cutoff_time ||= retention_days.days.ago
    end

    def positive_or_default(value, default_value)
      parsed = value.to_i
      parsed.positive? ? parsed : default_value
    end
  end
end
