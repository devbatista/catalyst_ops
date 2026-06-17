require "rails_helper"

RSpec.describe Cmd::MercadoPago::CreateCreditCardTrialSubscription do
  describe "#call" do
    it "usa mock fora de produção e ativa assinatura com período do cupom" do
      company = company_with_subscription
      coupon = create(:coupon, :trial, trial_frequency: 10, trial_frequency_type: "days")

      allow(Rails.env).to receive(:production?).and_return(false)
      allow(MercadoPago::MockData).to receive(:create_credit_card_payment).and_call_original

      result = described_class.new(company, "token_cartao", coupon).call
      subscription = company.current_subscription.reload

      expect(result).to be_success
      expect(MercadoPago::MockData).to have_received(:create_credit_card_payment).with(
        hash_including(
          external_reference: company.id.to_s,
          payer_email: company.email,
          card_token_id: "token_cartao",
          auto_recurring: hash_including(
            free_trial: { frequency: 10, frequency_type: "days" }
          )
        )
      )
      expect(subscription).to be_active
      expect(subscription.external_subscription_id).to be_present
      expect(subscription.end_date.to_date).to eq(10.days.from_now.to_date)
    end

    it "em produção envia payload para API" do
      company = company_with_subscription
      coupon = create(:coupon, :trial)
      client = instance_double(MercadoPago::Client)
      response = { "id" => "pre_trial", "status" => "authorized", "status_detail" => "authorized" }

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(MercadoPago::Client).to receive(:new).and_return(client)
      allow(client).to receive(:request).and_return(response)

      result = described_class.new(company, "token_cartao", coupon).call

      expect(result).to be_success
      expect(client).to have_received(:request).with(
        method: :post,
        path: "/preapproval",
        body: hash_including(
          reason: company.plan.reason,
          external_reference: company.id.to_s,
          payer_email: company.email,
          card_token_id: "token_cartao"
        )
      )
    end

    it "mantém assinatura pendente quando resposta é pending" do
      company = company_with_subscription
      coupon = create(:coupon, :trial)

      allow(Rails.env).to receive(:production?).and_return(false)
      allow(MercadoPago::MockData).to receive(:create_credit_card_payment).and_return(
        { "id" => "pre_pending", "status" => "pending", "status_detail" => "pending" }
      )

      result = described_class.new(company, "token_cartao", coupon).call

      expect(result).to be_success
      expect(company.current_subscription.reload).to be_pending
    end

    it "retorna falha quando a API rejeita assinatura" do
      company = company_with_subscription
      coupon = create(:coupon, :trial)

      allow(Rails.env).to receive(:production?).and_return(false)
      allow(MercadoPago::MockData).to receive(:create_credit_card_payment).and_return(
        { "id" => "pre_rejected", "status" => "rejected", "status_detail" => "cc_rejected" }
      )
      allow(Rails.logger).to receive(:error)

      result = described_class.new(company, "token_cartao", coupon).call

      expect(result).not_to be_success
      expect(result.errors).to eq("Falha ao criar a assinatura de teste no cartão: cc_rejected")
    end
  end

  def company_with_subscription
    plan = create(:plan)
    company = create(:company, plan: plan, payment_method: "credit_card")
    create(:subscription, company: company, subscription_plan: plan, status: :pending)
    company.reload
  end
end
