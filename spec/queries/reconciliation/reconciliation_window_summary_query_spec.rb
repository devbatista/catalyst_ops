require "rails_helper"

RSpec.describe Reconciliation::ReconciliationWindowSummaryQuery do
  describe ".call" do
    it "resume assinaturas do Mercado Pago dentro da janela" do
      credit_card_company = create(:company, payment_method: "credit_card")
      pix_company = create(:company, payment_method: "pix")
      boleto_company = create(:company, payment_method: "boleto")

      create(:subscription, company: credit_card_company, status: :active, gateway: "mercado_pago")
      create(:subscription, company: pix_company, status: :pending, gateway: "mercado_pago")
      create(:subscription, company: boleto_company, status: :cancelled, gateway: "mercado_pago")
      create(:subscription, company: boleto_company, status: :active, gateway: "stripe")
      create(:subscription, company: boleto_company, status: :active, gateway: "mercado_pago").tap do |subscription|
        subscription.update_columns(updated_at: 45.days.ago)
      end

      row = described_class.call(window_days: 30).first

      aggregate_failures do
        expect(row["total"]).to eq(2)
        expect(row["pending_count"]).to eq(1)
        expect(row["active_count"]).to eq(1)
        expect(row["credit_card_count"]).to eq(1)
        expect(row["pix_boleto_count"]).to eq(1)
      end
    end

    it "normaliza janela invalida para 30 dias" do
      allow(ActiveRecord::Base.connection).to receive(:exec_query)

      described_class.call(window_days: 0)

      expect(ActiveRecord::Base.connection).to have_received(:exec_query).with(include("INTERVAL '30 days'"))
    end
  end
end
