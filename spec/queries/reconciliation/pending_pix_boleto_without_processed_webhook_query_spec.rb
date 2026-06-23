require "rails_helper"

RSpec.describe Reconciliation::PendingPixBoletoWithoutProcessedWebhookQuery do
  describe ".call" do
    it "retorna pendentes de pix/boleto sem webhook processado e ignora plano gratuito" do
      paid_plan = create(:plan)
      free_plan = create(:plan, :starter)
      paid_company = create(:company, plan: paid_plan, payment_method: "pix")
      free_company = create(:company, plan: free_plan, payment_method: "pix")
      paid_subscription = create(
        :subscription,
        company: paid_company,
        subscription_plan: paid_plan,
        status: :pending,
        external_payment_id: "pay_paid"
      )
      create(
        :subscription,
        company: free_company,
        subscription_plan: free_plan,
        status: :pending,
        external_payment_id: "pay_free"
      )

      rows = described_class.call(window_days: 30).to_a

      expect(rows.map { |row| row["subscription_id"] }).to contain_exactly(paid_subscription.id)
    end

    it "normaliza janela invalida para 30 dias" do
      allow(ActiveRecord::Base.connection).to receive(:exec_query)

      described_class.call(window_days: 0)

      expect(ActiveRecord::Base.connection).to have_received(:exec_query).with(include("INTERVAL '30 days'"))
    end
  end
end
