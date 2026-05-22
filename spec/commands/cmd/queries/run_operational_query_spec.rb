require "rails_helper"

RSpec.describe Cmd::Queries::RunOperationalQuery do
  describe "#call" do
    it "executa query suportada repassando filtros" do
      query_result = ActiveRecord::Result.new(["subscription_id"], [["sub-1"]])

      allow(Reconciliation::PendingPixBoletoWithoutProcessedWebhookQuery)
        .to receive(:call).with(window_days: 7).and_return(query_result)

      result = described_class.new(
        query_name: :pending_pix_boleto_without_processed_webhook,
        params: { "window_days" => 7 }
      ).call

      expect(result).to be_success
      expect(result.columns).to eq(["subscription_id"])
      expect(result.rows).to eq([{ "subscription_id" => "sub-1" }])
    end

    it "retorna erro para query desconhecida" do
      result = described_class.new(query_name: :desconhecida).call

      expect(result).not_to be_success
      expect(result.rows).to eq([])
      expect(result.errors).to eq("Query nao suportada: desconhecida")
    end

    it "retorna erro quando a query levanta exceção" do
      allow(Webhooks::PossibleDuplicatePaymentEventsQuery).to receive(:call).and_raise(StandardError, "falha")

      result = described_class.new(query_name: :possible_duplicate_payment_events).call

      expect(result).not_to be_success
      expect(result.errors).to eq("falha")
    end
  end

  describe ".available_queries" do
    it "lista queries configuradas" do
      expect(described_class.available_queries).to include(:pending_pix_boleto_without_processed_webhook, :possible_duplicate_payment_events)
    end
  end
end
