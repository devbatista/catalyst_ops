require "rails_helper"

RSpec.describe MercadoPago::Subscriptions do
  describe ".compute_period_end" do
    it "calcula período em dias, semanas e meses" do
      paid_at = Time.zone.local(2026, 5, 22, 10, 0, 0)

      expect(described_class.compute_period_end(paid_at, frequency: 10, frequency_type: "days")).to eq(paid_at + 10.days)
      expect(described_class.compute_period_end(paid_at, frequency: 2, frequency_type: "weeks")).to eq(paid_at + 2.weeks)
      expect(described_class.compute_period_end(paid_at, frequency: 1, frequency_type: "months")).to eq(paid_at + 1.month)
      expect(described_class.compute_period_end(paid_at, frequency: 1, frequency_type: "invalid")).to eq(paid_at + 1.month)
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

    it "consulta a API em produção" do
      client = instance_double(MercadoPago::Client)
      payload = { "id" => "pre_123", "status" => "authorized" }

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:request).with(method: :get, path: "/preapproval/pre_123").and_return(payload)

      expect(described_class.fetch_preapproval("pre_123")).to eq(payload)
    end
  end

  describe ".fetch_payment" do
    it "consulta a API em produção" do
      client = instance_double(MercadoPago::Client)
      payload = { "id" => "pay_123", "status" => "approved" }

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:request).with(method: :get, path: "/v1/payments/pay_123").and_return(payload)

      expect(described_class.fetch_payment("pay_123")).to eq(payload)
    end

    it "retorna nil e registra erro quando a API falha" do
      client = instance_double(MercadoPago::Client)

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:request).and_raise(StandardError, "fora")
      allow(Rails.logger).to receive(:error)

      expect(described_class.fetch_payment("pay_123")).to be_nil
      expect(Rails.logger).to have_received(:error).with("[MercadoPago::Subscriptions] Erro ao consultar payment pay_123: fora")
    end
  end

  describe ".fetch_authorized_payment" do
    it "consulta a API em produção" do
      client = instance_double(MercadoPago::Client)
      payload = { "id" => "auth_123", "payment" => { "id" => "pay_123" } }

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:request).with(method: :get, path: "/authorized_payments/auth_123").and_return(payload)

      expect(described_class.fetch_authorized_payment("auth_123")).to eq(payload)
    end

    it "retorna nil e registra erro quando a API falha" do
      client = instance_double(MercadoPago::Client)

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:request).and_raise(StandardError, "fora")
      allow(Rails.logger).to receive(:error)

      expect(described_class.fetch_authorized_payment("auth_123")).to be_nil
      expect(Rails.logger).to have_received(:error).with("[MercadoPago::Subscriptions] Erro ao consultar authorized payment auth_123: fora")
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

    it "retorna nil sem assinatura disponível" do
      expect(described_class.mock_payment("pay_1")).to be_nil
    end

    it "normaliza status remoto cancelado e método de cartão" do
      company = create(:company, payment_method: "credit_card")
      create(:subscription, company: company, external_payment_id: "pay_2")

      result = described_class.mock_payment("pay_2", mock_status: "rejected")

      expect(result).to include(
        "status" => "cancelled",
        "status_detail" => "by_collector",
        "payment_method_id" => "master",
        "payment_type_id" => "credit_card"
      )
    end
  end

  describe ".mock_preapproval" do
    it "retorna nil sem assinatura para o preapproval" do
      expect(described_class.mock_preapproval("pre_inexistente")).to be_nil
    end
  end

  describe ".mock_authorized_payment" do
    it "retorna nil sem assinatura com assinatura externa" do
      expect(described_class.mock_authorized_payment("auth_1")).to be_nil
    end
  end
end
