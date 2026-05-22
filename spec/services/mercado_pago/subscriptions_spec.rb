require "rails_helper"

RSpec.describe MercadoPago::Subscriptions do
  describe ".compute_period_end" do
    it "calcula período em dias, semanas e meses" do
      paid_at = Time.zone.local(2026, 5, 22, 10, 0, 0)

      expect(described_class.compute_period_end(paid_at, frequency: 10, frequency_type: "days")).to eq(paid_at + 10.days)
      expect(described_class.compute_period_end(paid_at, frequency: 2, frequency_type: "weeks")).to eq(paid_at + 2.weeks)
      expect(described_class.compute_period_end(paid_at, frequency: 1, frequency_type: "months")).to eq(paid_at + 1.month)
    end

    it "retorna nil sem data de pagamento" do
      expect(described_class.compute_period_end(nil)).to be_nil
    end
  end

  describe ".fetch_preapproval" do
    it "usa mock fora de produção" do
      subscription = create(:subscription, external_subscription_id: "pre_123", external_reference: "company-1")

      allow(Rails.env).to receive(:production?).and_return(false)

      result = described_class.fetch_preapproval("pre_123")

      expect(result).to include(
        "id" => "pre_123",
        "external_reference" => "company-1",
        "preapproval_plan_id" => subscription.preapproval_plan_id
      )
    end

    it "retorna nil quando integração falha em produção" do
      client = instance_double(MercadoPago::Client)

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:request).and_raise(StandardError, "erro")
      allow(Rails.logger).to receive(:error)

      expect(described_class.fetch_preapproval("pre_123")).to be_nil
    end
  end

  describe ".mock_payment" do
    it "monta pagamento mockado conforme método de pagamento da empresa" do
      company = create(:company, payment_method: "pix")
      subscription = create(:subscription, company: company, external_payment_id: "pay_1", transaction_amount: 88)

      result = described_class.mock_payment("pay_1", mock_status: "pending")

      expect(result).to include("id" => "pay_1", "status" => "pending", "payment_method_id" => "pix")
      expect(result["external_reference"]).to eq(subscription.external_reference)
      expect(result["transaction_amount"]).to eq(88)
    end
  end
end
