require "rails_helper"

RSpec.describe Cmd::MercadoPago::CreateCreditCardPayment do
  describe "#call" do
    it "usa mock fora de produção e ativa assinatura autorizada" do
      company = company_with_subscription(payment_method: "credit_card")

      allow(Rails.env).to receive(:production?).and_return(false)
      allow(MercadoPago::MockData).to receive(:create_credit_card_payment).and_call_original

      result = described_class.new(company, "token_cartao").call
      subscription = company.current_subscription.reload

      aggregate_failures do
        expect(result).to be_success
        expect(MercadoPago::MockData).to have_received(:create_credit_card_payment).with(hash_including(card_token_id: "token_cartao"))
        expect(subscription).to be_active
        expect(subscription.external_subscription_id).to be_present
        expect(subscription.raw_payload["status"]).to eq("authorized")
      end
    end

    it "em produção envia payload para API e ativa assinatura autorizada" do
      company = company_with_subscription(payment_method: "credit_card")
      client = instance_double(MercadoPago::Client)
      response = { "id" => "preapproval_123", "status" => "authorized", "status_detail" => "authorized" }

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(MercadoPago::Client).to receive(:new).and_return(client)
      allow(client).to receive(:request).and_return(response)

      result = described_class.new(company, "token_cartao").call

      aggregate_failures do
        expect(result).to be_success
        expect(client).to have_received(:request).with(
          method: :post,
          path: "/preapproval",
          body: hash_including(
            preapproval_plan_id: company.plan.external_id,
            external_reference: company.id.to_s,
            payer_email: company.email,
            card_token_id: "token_cartao",
            status: "authorized"
          )
        )
        expect(company.current_subscription.reload).to be_active
      end
    end

    it "mantém assinatura pendente quando resposta é pending" do
      company = company_with_subscription(payment_method: "credit_card")

      allow(Rails.env).to receive(:production?).and_return(false)
      allow(MercadoPago::MockData).to receive(:create_credit_card_payment).and_return(
        { "id" => "preapproval_pending", "status" => "pending", "status_detail" => "pending" }
      )

      result = described_class.new(company, "token_cartao").call

      aggregate_failures do
        expect(result).to be_success
        expect(company.current_subscription.reload).to be_pending
      end
    end

    it "retorna falha quando API retorna status não suportado" do
      company = company_with_subscription(payment_method: "credit_card")

      allow(Rails.env).to receive(:production?).and_return(false)
      allow(MercadoPago::MockData).to receive(:create_credit_card_payment).and_return(
        { "id" => "preapproval_rejected", "status" => "rejected", "status_detail" => "cc_rejected" }
      )
      allow(Rails.logger).to receive(:error)

      result = described_class.new(company, "token_cartao").call

      aggregate_failures do
        expect(result).not_to be_success
        expect(result.errors).to eq("Failed to create credit card payment: cc_rejected")
        expect(Rails.logger).to have_received(:error).with("Erro ao criar solicitação de pagamento para a company id #{company.id}: Failed to create credit card payment: cc_rejected")
      end
    end
  end

  def company_with_subscription(payment_method:)
    plan = create(:plan)
    company = create(:company, plan: plan, payment_method: payment_method)
    create(:subscription, company: company, subscription_plan: plan, status: :pending)
    company.reload
  end
end
