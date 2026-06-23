require "rails_helper"

RSpec.describe Cmd::Subscriptions::ReconcileSubscription do
  describe "#call" do
    it "retorna falha quando assinatura não existe" do
      result = described_class.new(subscription_id: SecureRandom.uuid).call

      aggregate_failures do
        expect(result).not_to be_success
        expect(result.subscription).to be_nil
        expect(result.errors).to eq("Assinatura não encontrada")
      end
    end

    it "registra erro para método de pagamento não suportado" do
      subscription = subscription_for(payment_method: "pix", external_payment_id: "pay_unsupported")
      subscription.company.update_columns(payment_method: "dinheiro")

      result = described_class.new(subscription_id: subscription.id, source_job: "spec", window_days: 5).call
      event = SubscriptionReconciliationEvent.last

      aggregate_failures do
        expect(result).not_to be_success
        expect(result.errors).to include("Metodo de pagamento")
        expect(event).to have_attributes(
          subscription_id: subscription.id,
          result_status: "error",
          payment_method: "dinheiro",
          gateway_identifier: "pay_unsupported"
        )
      end
    end

    it "ignora assinatura de plano gratuito sem consultar gateway" do
      plan = create(:plan, :starter)
      company = create(:company, plan: plan, payment_method: "pix")
      subscription = create(:subscription, company: company, subscription_plan: plan, status: :active, external_payment_id: "pay_free")

      allow(MercadoPago::Subscriptions).to receive(:fetch_payment)

      result = described_class.new(subscription_id: subscription.id).call

      expect(result).to be_success
      expect(MercadoPago::Subscriptions).not_to have_received(:fetch_payment)
      expect(SubscriptionReconciliationEvent.where(subscription: subscription)).to be_empty
    end

    it "registra erro para cartão sem identificador externo" do
      subscription = subscription_for(payment_method: "credit_card", external_subscription_id: nil)

      result = described_class.new(subscription_id: subscription.id).call

      aggregate_failures do
        expect(result).not_to be_success
        expect(result.errors).to eq("Assinatura de cartao sem preapproval_id para reconciliacao")
        expect(SubscriptionReconciliationEvent.last).to have_attributes(result_status: "error", payment_method: "credit_card")
      end
    end

    it "registra erro para pix sem payment_id" do
      subscription = subscription_for(payment_method: "pix", external_payment_id: nil)

      result = described_class.new(subscription_id: subscription.id).call

      aggregate_failures do
        expect(result).not_to be_success
        expect(result.errors).to eq("Assinatura sem payment_id para reconciliacao")
        expect(SubscriptionReconciliationEvent.last).to have_attributes(result_status: "error", payment_method: "pix")
      end
    end

    it "reconcilia cartão aprovado com sucesso e resolve divergência" do
      subscription = subscription_for(payment_method: "credit_card", status: :pending, external_subscription_id: "pre_123")
      preapproval = { "id" => "pre_123", "status" => "authorized", "external_reference" => subscription.company_id }

      allow(MercadoPago::Subscriptions).to receive(:fetch_preapproval).with("pre_123").and_return(preapproval)

      result = described_class.new(subscription_id: subscription.id, source_job: "spec", window_days: 7).call
      event = SubscriptionReconciliationEvent.last

      aggregate_failures do
        expect(result).to be_success
        expect(subscription.reload).to be_active
        expect(event).to have_attributes(
          source_job: "spec",
          window_days: 7,
          payment_method: "credit_card",
          gateway_identifier: "pre_123",
          gateway_status: "authorized",
          local_status_before: "pending",
          local_status_after: "active",
          divergent: false,
          resolved: true,
          result_status: "success"
        )
      end
    end

    it "reconcilia pix aprovado com sucesso" do
      subscription = subscription_for(payment_method: "pix", status: :pending, external_payment_id: "pay_pix")
      payment = payment_payload(subscription, payment_id: "pay_pix", status: "approved")

      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).with("pay_pix").and_return(payment)

      result = described_class.new(subscription_id: subscription.id).call

      aggregate_failures do
        expect(result).to be_success
        expect(subscription.reload).to be_active
        expect(SubscriptionReconciliationEvent.last).to have_attributes(payment_method: "pix", gateway_status: "approved", result_status: "success")
      end
    end

    it "reconcilia boleto rejeitado cancelando assinatura" do
      subscription = subscription_for(payment_method: "boleto", status: :active, external_payment_id: "pay_boleto")
      payment = payment_payload(subscription, payment_id: "pay_boleto", status: "rejected")

      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).with("pay_boleto").and_return(payment)

      result = described_class.new(subscription_id: subscription.id).call

      aggregate_failures do
        expect(result).to be_success
        expect(subscription.reload).to be_cancelled
        expect(SubscriptionReconciliationEvent.last).to have_attributes(payment_method: "boleto", gateway_status: "rejected", result_status: "success")
      end
    end

    it "registra evento de erro best-effort quando consulta ao gateway falha" do
      subscription = subscription_for(payment_method: "pix", external_payment_id: "pay_erro")

      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).and_raise(StandardError, "gateway fora")

      result = described_class.new(subscription_id: subscription.id).call

      aggregate_failures do
        expect(result).not_to be_success
        expect(result.errors).to eq("gateway fora")
        expect(SubscriptionReconciliationEvent.last).to have_attributes(result_status: "error", error_message: "gateway fora")
      end
    end
  end

  def subscription_for(payment_method:, status: :pending, external_payment_id: nil, external_subscription_id: nil)
    plan = create(:plan)
    company = create(:company, plan: plan, payment_method: payment_method)
    create(
      :subscription,
      company: company,
      subscription_plan: plan,
      status: status,
      external_payment_id: external_payment_id,
      external_subscription_id: external_subscription_id
    )
  end

  def payment_payload(subscription, payment_id:, status:)
    {
      "id" => payment_id,
      "status" => status,
      "external_reference" => subscription.company_id,
      "date_approved" => Time.current.iso8601
    }
  end
end
