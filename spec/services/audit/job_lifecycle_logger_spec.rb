require "rails_helper"

RSpec.describe Audit::JobLifecycleLogger do
  before do
    allow(Audit::Log).to receive(:call)
  end

  it "registra início do job" do
    described_class.new(job_name: "TesteJob", jid: "jid-1", metadata: { lote: 2 }).started

    expect(Audit::Log).to have_received(:call).with(
      action: "job.started",
      metadata: hash_including(job_name: "TesteJob", jid: "jid-1", lote: 2, event: "job_started")
    )
  end

  it "registra conclusão com duração" do
    started_at = 2.seconds.ago

    described_class.new(job_name: "TesteJob", jid: "jid-1").completed(started_at: started_at, extra: { total: 3 })

    expect(Audit::Log).to have_received(:call).with(
      action: "job.completed",
      metadata: hash_including(
        job_name: "TesteJob",
        jid: "jid-1",
        event: "job_completed",
        started_at: started_at,
        duration_ms: be_between(1_000, 3_000),
        total: 3
      )
    )
  end

  it "registra falha com classe e mensagem do erro" do
    error = StandardError.new("boom")

    described_class.new(job_name: "TesteJob", jid: "jid-1").failed(error: error)

    expect(Audit::Log).to have_received(:call).with(
      action: "job.failed",
      metadata: hash_including(error_class: "StandardError", error_message: "boom")
    )
  end
end
