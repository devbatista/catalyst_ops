require "rails_helper"

RSpec.describe Subscriptions::FinalizeScheduledCancellationsJob, type: :job do
  describe "#perform" do
    it "registra auditoria de inicio e conclusao com contadores do processamento" do
      subscription = create(
        :subscription,
        status: :active,
        cancel_at_period_end: true,
        cancel_effective_on: Date.current
      )
      audit_logger = instance_double(Audit::JobLifecycleLogger, started: true, completed: true, failed: true)
      command = instance_double(Cmd::Subscriptions::FinalizeScheduledCancellation, call: result(true))

      allow(Audit::JobLifecycleLogger).to receive(:new).and_return(audit_logger)
      allow(Cmd::Subscriptions::FinalizeScheduledCancellation).to receive(:new).and_return(command)

      described_class.new.perform

      aggregate_failures do
        expect(audit_logger).to have_received(:started).with(event: "scheduled_cancellations_started")
        expect(audit_logger).to have_received(:completed).with(
          event: "scheduled_cancellations_completed",
          started_at: kind_of(Time),
          extra: {
            subscriptions_found: 1,
            subscriptions_processed: 1,
            subscriptions_success: 1,
            subscriptions_error: 0
          }
        )
        expect(Cmd::Subscriptions::FinalizeScheduledCancellation)
          .to have_received(:new).with(subscription_id: subscription.id)
      end
    end

    it "registra auditoria de falha quando o job falha antes do processamento" do
      audit_logger = instance_double(Audit::JobLifecycleLogger, started: true, completed: true, failed: true)
      error = StandardError.new("boom")

      allow(Audit::JobLifecycleLogger).to receive(:new).and_return(audit_logger)
      allow(Subscription).to receive(:scheduled_for_cancellation_due).and_raise(error)

      expect { described_class.new.perform }.to raise_error(error)

      expect(audit_logger).to have_received(:failed).with(
        event: "scheduled_cancellations_failed",
        error: error
      )
    end
  end

  def result(success, errors = nil)
    Cmd::Subscriptions::FinalizeScheduledCancellation::Result.new(success, nil, errors)
  end
end
