require "rails_helper"

RSpec.describe Subscriptions::ReconcileSubscriptionsJob, type: :job do
  describe "#perform" do
    it "usa janela padrão de 30 dias e reconcilia assinaturas elegíveis" do
      subscription = create(:subscription)
      command = instance_double(Cmd::Subscriptions::ReconcileSubscription, call: reconcile_result(true))
      audit_logger = instance_double(Audit::JobLifecycleLogger, started: true, completed: true, failed: true)
      job = described_class.new

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("SUBSCRIPTIONS_RECONCILIATION_WINDOW_DAYS", 30).and_return(30)
      allow(Audit::JobLifecycleLogger).to receive(:new).and_return(audit_logger)
      allow(job).to receive(:subscriptions_to_reconcile).and_return(Subscription.where(id: subscription.id))
      allow(Cmd::Subscriptions::ReconcileSubscription).to receive(:new).and_return(command)
      allow(Rails.logger).to receive(:info)

      job.perform

      aggregate_failures do
        expect(Cmd::Subscriptions::ReconcileSubscription).to have_received(:new).with(
          subscription_id: subscription.id,
          source_job: "Subscriptions::ReconcileSubscriptionsJob",
          window_days: 30
        )
        expect(audit_logger).to have_received(:completed).with(
          event: "reconciliation_completed",
          started_at: kind_of(Time),
          extra: {
            window_days: 30,
            subscriptions_found: 1,
            subscriptions_processed: 1,
            subscriptions_success: 1,
            subscriptions_error: 0
          }
        )
      end
    end

    it "usa janela configurada por variável de ambiente" do
      subscription = create(:subscription)
      command = instance_double(Cmd::Subscriptions::ReconcileSubscription, call: reconcile_result(true))
      audit_logger = instance_double(Audit::JobLifecycleLogger, started: true, completed: true, failed: true)
      job = described_class.new

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("SUBSCRIPTIONS_RECONCILIATION_WINDOW_DAYS", 30).and_return("12")
      allow(Audit::JobLifecycleLogger).to receive(:new).and_return(audit_logger)
      allow(job).to receive(:subscriptions_to_reconcile).and_return(Subscription.where(id: subscription.id))
      allow(Cmd::Subscriptions::ReconcileSubscription).to receive(:new).and_return(command)

      job.perform

      expect(Cmd::Subscriptions::ReconcileSubscription).to have_received(:new).with(
        subscription_id: subscription.id,
        source_job: "Subscriptions::ReconcileSubscriptionsJob",
        window_days: 12
      )
    end

    it "registra conclusão sem processamento quando não há elegíveis" do
      audit_logger = instance_double(Audit::JobLifecycleLogger, started: true, completed: true, failed: true)
      job = described_class.new

      allow(Audit::JobLifecycleLogger).to receive(:new).and_return(audit_logger)
      allow(job).to receive(:subscriptions_to_reconcile).and_return(Subscription.none)
      allow(Cmd::Subscriptions::ReconcileSubscription).to receive(:new)
      allow(Rails.logger).to receive(:info)

      job.perform

      aggregate_failures do
        expect(Cmd::Subscriptions::ReconcileSubscription).not_to have_received(:new)
        expect(Rails.logger).to have_received(:info).with("[Subscriptions::ReconcileSubscriptionsJob] Nenhuma assinatura elegivel para reconciliacao (janela: 30 dias).")
        expect(audit_logger).to have_received(:completed).with(
          event: "reconciliation_completed",
          started_at: kind_of(Time),
          extra: {
            window_days: 30,
            subscriptions_found: 0,
            subscriptions_processed: 0,
            subscriptions_success: 0,
            subscriptions_error: 0
          }
        )
      end
    end

    it "contabiliza erro quando o command retorna falha" do
      subscription = create(:subscription)
      command = instance_double(Cmd::Subscriptions::ReconcileSubscription, call: reconcile_result(false, "erro remoto"))
      audit_logger = instance_double(Audit::JobLifecycleLogger, started: true, completed: true, failed: true)
      job = described_class.new

      allow(Audit::JobLifecycleLogger).to receive(:new).and_return(audit_logger)
      allow(job).to receive(:subscriptions_to_reconcile).and_return(Subscription.where(id: subscription.id))
      allow(Cmd::Subscriptions::ReconcileSubscription).to receive(:new).and_return(command)
      allow(Rails.logger).to receive(:error)

      job.perform

      aggregate_failures do
        expect(Rails.logger).to have_received(:error).with("[Subscriptions::ReconcileSubscriptionsJob] Falha ao reconciliar assinatura ID #{subscription.id}: erro remoto")
        expect(audit_logger).to have_received(:completed).with(
          event: "reconciliation_completed",
          started_at: kind_of(Time),
          extra: {
            window_days: 30,
            subscriptions_found: 1,
            subscriptions_processed: 1,
            subscriptions_success: 0,
            subscriptions_error: 1
          }
        )
      end
    end
  end

  def reconcile_result(success, errors = nil)
    Cmd::Subscriptions::ReconcileSubscription::Result.new(success, nil, errors)
  end
end
