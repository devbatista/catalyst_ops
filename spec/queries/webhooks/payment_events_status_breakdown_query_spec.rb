require "rails_helper"

RSpec.describe Webhooks::PaymentEventsStatusBreakdownQuery do
  describe ".call" do
    it "agrupa eventos de pagamento do Mercado Pago por status" do
      create(:webhook_event, status: "processed")
      create(:webhook_event, status: "processed")
      create(:webhook_event, status: "failed")
      create(:webhook_event, status: "received", event_type: "subscription")
      create(:webhook_event, status: "received", provider: "stripe")
      create(:webhook_event, status: "received").tap do |event|
        event.update_columns(created_at: 45.days.ago)
      end

      rows = described_class.call(window_days: 30).to_a.index_by { |row| row["status"] }

      aggregate_failures do
        expect(rows.keys).to contain_exactly("processed", "failed")
        expect(rows.dig("processed", "total")).to eq(2)
        expect(rows.dig("failed", "total")).to eq(1)
      end
    end

    it "normaliza janela invalida para 30 dias" do
      allow(ActiveRecord::Base.connection).to receive(:exec_query)

      described_class.call(window_days: -10)

      expect(ActiveRecord::Base.connection).to have_received(:exec_query).with(include("INTERVAL '30 days'"))
    end
  end
end
