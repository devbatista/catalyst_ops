require "rails_helper"

RSpec.describe Audit::CleanupEventsJob, type: :job do
  let(:cleanup_service) { instance_double(Audit::CleanupOldEvents, call: cleanup_result) }
  let(:job_audit) do
    instance_double(
      Audit::JobLifecycleLogger,
      started: true,
      completed: true,
      failed: true
    )
  end
  let(:cleanup_result) { { total_candidates: 3, deleted_count: 2, dry_run: false } }

  before do
    allow(Audit::CleanupOldEvents).to receive(:new).and_return(cleanup_service)
    allow(Audit::JobLifecycleLogger).to receive(:new).and_return(job_audit)
    allow(Rails.logger).to receive(:info)
  end

  around do |example|
    old_values = {
      "AUDIT_LOG_RETENTION_DAYS" => ENV["AUDIT_LOG_RETENTION_DAYS"],
      "AUDIT_LOG_CLEANUP_BATCH_SIZE" => ENV["AUDIT_LOG_CLEANUP_BATCH_SIZE"],
      "AUDIT_LOG_CLEANUP_DRY_RUN" => ENV["AUDIT_LOG_CLEANUP_DRY_RUN"]
    }

    example.run
  ensure
    old_values.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end

  it "executa a limpeza com parametros do ambiente e registra ciclo do job" do
    ENV["AUDIT_LOG_RETENTION_DAYS"] = "90"
    ENV["AUDIT_LOG_CLEANUP_BATCH_SIZE"] = "250"
    ENV["AUDIT_LOG_CLEANUP_DRY_RUN"] = "true"

    described_class.new.perform

    aggregate_failures do
      expect(Audit::CleanupOldEvents).to have_received(:new).with(
        retention_days: 90,
        batch_size: 250,
        dry_run: true
      )
      expect(job_audit).to have_received(:started).with(event: "audit_cleanup_started")
      expect(job_audit).to have_received(:completed).with(
        event: "audit_cleanup_completed",
        started_at: kind_of(Time),
        extra: cleanup_result
      )
      expect(Rails.logger).to have_received(:info).with(include("Limpeza de audit_events concluida"))
    end
  end

  it "usa defaults quando os parametros do ambiente sao invalidos" do
    ENV["AUDIT_LOG_RETENTION_DAYS"] = "0"
    ENV["AUDIT_LOG_CLEANUP_BATCH_SIZE"] = "-1"
    ENV["AUDIT_LOG_CLEANUP_DRY_RUN"] = "false"

    described_class.new.perform

    expect(Audit::CleanupOldEvents).to have_received(:new).with(
      retention_days: 180,
      batch_size: 1000,
      dry_run: false
    )
  end

  it "registra falha e relanca o erro" do
    error = StandardError.new("boom")
    allow(cleanup_service).to receive(:call).and_raise(error)

    expect { described_class.new.perform }.to raise_error(error)

    expect(job_audit).to have_received(:failed).with(
      event: "audit_cleanup_failed",
      error: error,
      extra: {
        retention_days: 180,
        batch_size: 1000,
        dry_run: false
      }
    )
  end
end
