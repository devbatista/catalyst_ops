require "rails_helper"

RSpec.describe MercadoPago::WebhookProcessor do
  before do
    allow(Audit::Log).to receive(:call)
  end

  describe "#call" do
    it "ignora tipos de webhook desconhecidos" do
      result = described_class.new(payload: { "type" => "merchant_order", "data" => { "id" => "order_1" } }).call

      expect(result).to be_success
      expect(result.message).to include("Webhook ignorado")
    end

    it "falha quando webhook de pagamento não possui identificador" do
      result = described_class.new(payload: { "type" => "payment", "data" => {} }).call

      expect(result).not_to be_success
      expect(result.message).to eq("Webhook de payment sem data.id")
    end

    it "ativa assinatura quando pagamento é aprovado" do
      subscription = create(:subscription, status: :pending, external_payment_id: "pay_123")
      payment = payment_payload_for(subscription, payment_id: "pay_123", status: "approved")

      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).with("pay_123", mock_status: "approved").and_return(payment)

      result = described_class.new(payload: webhook_payload("payment", "pay_123", status: "approved")).call

      aggregate_failures do
        expect(result).to be_success
        expect(subscription.reload).to be_active
        expect(subscription.raw_payload).to include("id" => "pay_123", "status" => "approved")
        expect(Audit::Log).to have_received(:call).with(hash_including(action: "subscription.payment.approved"))
      end
    end

    it "mantém assinatura pendente quando pagamento ainda está em análise" do
      subscription = create(:subscription, status: :active, external_payment_id: "pay_pending")
      payment = payment_payload_for(subscription, payment_id: "pay_pending", status: "in_process")

      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).and_return(payment)

      result = described_class.new(payload: webhook_payload("payment", "pay_pending", status: "in_process")).call

      expect(result).to be_success
      expect(subscription.reload).to be_pending
    end

    it "cancela assinatura quando pagamento falha" do
      subscription = create(:subscription, status: :active, external_payment_id: "pay_failed")
      payment = payment_payload_for(subscription, payment_id: "pay_failed", status: "rejected")

      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).and_return(payment)

      result = described_class.new(payload: webhook_payload("payment", "pay_failed", status: "rejected")).call

      expect(result).to be_success
      expect(subscription.reload).to be_cancelled
    end

    it "retorna falha quando pagamento não existe na API" do
      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).and_return(nil)

      result = described_class.new(payload: webhook_payload("payment", "pay_missing")).call

      expect(result).not_to be_success
      expect(result.message).to eq("Pagamento pay_missing nao encontrado na API")
    end

    it "retorna falha quando assinatura local não é encontrada" do
      payment = { "id" => "pay_orphan", "status" => "approved", "external_reference" => SecureRandom.uuid }

      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).and_return(payment)

      result = described_class.new(payload: webhook_payload("payment", "pay_orphan")).call

      expect(result).not_to be_success
      expect(result.message).to include("Assinatura local nao encontrada")
    end

    it "processa preapproval autorizado" do
      subscription = create(:subscription, status: :pending, external_subscription_id: "pre_123")
      preapproval = {
        "id" => "pre_123",
        "status" => "authorized",
        "external_reference" => subscription.company_id
      }

      allow(MercadoPago::Subscriptions).to receive(:fetch_preapproval).with("pre_123").and_return(preapproval)

      result = described_class.new(payload: webhook_payload("subscription_preapproval", "pre_123")).call

      aggregate_failures do
        expect(result).to be_success
        expect(subscription.reload).to be_active
        expect(subscription.external_subscription_id).to eq("pre_123")
        expect(subscription.raw_payload).to include("status" => "authorized")
      end
    end

    it "processa pagamento autorizado de assinatura" do
      subscription = create(:subscription, status: :pending, external_subscription_id: "pre_456")
      authorized_payment = {
        "id" => "auth_123",
        "preapproval_id" => "pre_456",
        "debit_date" => Time.zone.local(2026, 5, 20, 12).iso8601,
        "payment" => { "status" => "approved" }
      }

      allow(MercadoPago::Subscriptions).to receive(:fetch_authorized_payment).with("auth_123").and_return(authorized_payment)

      result = described_class.new(payload: webhook_payload("subscription_authorized_payment", "auth_123")).call

      aggregate_failures do
        expect(result).to be_success
        expect(subscription.reload).to be_active
        expect(subscription.start_date).to eq(Date.new(2026, 5, 20))
        expect(subscription.end_date).to be_present
        expect(subscription.raw_payload).to include("id" => "auth_123")
      end
    end

    it "retorna falha quando ocorre exceção no processamento" do
      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).and_raise(StandardError, "api fora")

      result = described_class.new(payload: webhook_payload("payment", "pay_error")).call

      expect(result).not_to be_success
      expect(result.message).to eq("api fora")
    end
  end

  def webhook_payload(type, id, status: nil)
    payload = {
      "type" => type,
      "data" => { "id" => id }
    }
    payload["data"]["status"] = status if status.present?
    payload
  end

  def payment_payload_for(subscription, payment_id:, status:)
    {
      "id" => payment_id,
      "status" => status,
      "external_reference" => subscription.company_id
    }
  end
end
