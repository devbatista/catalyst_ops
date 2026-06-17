require "rails_helper"

RSpec.describe Subscriptions::ReprocessPendingPaymentsJob, type: :job do
  describe "#perform" do
    it "usa janela padrão de 30 dias e reprocessa assinaturas pendentes elegíveis" do
      subscription_id = SecureRandom.uuid
      query = instance_double(Cmd::Queries::RunOperationalQuery, call: query_result(true, [{ "subscription_id" => subscription_id }]))
      command = instance_double(Cmd::Subscriptions::ReconcileSubscription, call: reconcile_result(true))

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("SUBSCRIPTIONS_PENDING_REPROCESS_WINDOW_DAYS", 30).and_return(30)
      allow(Cmd::Queries::RunOperationalQuery).to receive(:new).and_return(query)
      allow(Cmd::Subscriptions::ReconcileSubscription).to receive(:new).and_return(command)
      allow(Rails.logger).to receive(:info)

      described_class.new.perform

      aggregate_failures do
        expect(Cmd::Queries::RunOperationalQuery).to have_received(:new).with(
          query_name: :pending_pix_boleto_without_processed_webhook,
          params: { window_days: 30 }
        )
        expect(Cmd::Subscriptions::ReconcileSubscription).to have_received(:new).with(
          subscription_id: subscription_id,
          source_job: "Subscriptions::ReprocessPendingPaymentsJob",
          window_days: 30
        )
        expect(Rails.logger).to have_received(:info).with("[Subscriptions::ReprocessPendingPaymentsJob] Assinatura ID #{subscription_id} reprocessada com sucesso.")
      end
    end

    it "usa janela configurada por variável de ambiente" do
      query = instance_double(Cmd::Queries::RunOperationalQuery, call: query_result(true, []))

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("SUBSCRIPTIONS_PENDING_REPROCESS_WINDOW_DAYS", 30).and_return("9")
      allow(Cmd::Queries::RunOperationalQuery).to receive(:new).and_return(query)

      described_class.new.perform

      expect(Cmd::Queries::RunOperationalQuery).to have_received(:new).with(
        query_name: :pending_pix_boleto_without_processed_webhook,
        params: { window_days: 9 }
      )
    end

    it "registra log quando não há pendentes elegíveis" do
      query = instance_double(Cmd::Queries::RunOperationalQuery, call: query_result(true, []))

      allow(Cmd::Queries::RunOperationalQuery).to receive(:new).and_return(query)
      allow(Rails.logger).to receive(:info)

      described_class.new.perform

      expect(Rails.logger).to have_received(:info).with("[Subscriptions::ReprocessPendingPaymentsJob] Nenhuma assinatura pending sem webhook para reprocessar (janela: 30 dias).")
    end

    it "registra erro quando a query operacional falha" do
      query = instance_double(Cmd::Queries::RunOperationalQuery, call: query_result(false, [], "consulta indisponível"))

      allow(Cmd::Queries::RunOperationalQuery).to receive(:new).and_return(query)
      allow(Rails.logger).to receive(:error)

      described_class.new.perform

      expect(Rails.logger).to have_received(:error).with("[Subscriptions::ReprocessPendingPaymentsJob] Falha ao carregar query operacional: consulta indisponível")
    end
  end

  def query_result(success, rows, errors = nil)
    Cmd::Queries::RunOperationalQuery::Result.new(success, rows, [], errors)
  end

  def reconcile_result(success, errors = nil)
    Cmd::Subscriptions::ReconcileSubscription::Result.new(success, nil, errors)
  end
end
