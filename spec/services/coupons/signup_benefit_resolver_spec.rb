require "rails_helper"

RSpec.describe Coupons::SignupBenefitResolver do
  before do
    allow(Audit::Log).to receive(:call)
  end

  describe "#call" do
    it "falha sem plano" do
      result = described_class.new(plan: nil, coupon_code: "PROMO").call

      expect(result).not_to be_success
      expect(result.errors).to eq("Plano inválido.")
    end

    it "retorna valores originais sem cupom" do
      plan = create(:plan, transaction_amount: 120)

      result = described_class.new(plan: plan, coupon_code: "").call

      aggregate_failures do
        expect(result).to be_success
        expect(result.coupon).to be_nil
        expect(result.original_amount).to eq(120)
        expect(result.discount_amount).to eq(0)
        expect(result.final_amount).to eq(120)
      end
    end

    it "aplica cupom válido normalizando o código" do
      plan = create(:plan, transaction_amount: 200)
      coupon = create(:coupon, code: "PROMO20", discount_value: 20)

      result = described_class.new(plan: plan, coupon_code: " promo20 ").call

      expect(result).to be_success
      expect(result.coupon).to eq(coupon)
      expect(result.discount_amount).to eq(40)
      expect(result.final_amount).to eq(160)
    end

    it "rejeita cupom inexistente e registra auditoria" do
      plan = create(:plan)

      result = described_class.new(plan: plan, coupon_code: "INVALIDO").call

      expect(result).not_to be_success
      expect(result.errors).to eq("Cupom inválido.")
      expect(Audit::Log).to have_received(:call).with(
        action: "coupon.rejected",
        resource: nil,
        metadata: hash_including(coupon_code: "INVALIDO", reason: "Cupom inválido.")
      )
    end

    it "rejeita cupom indisponível" do
      plan = create(:plan)
      coupon = create(:coupon, active: false)

      result = described_class.new(plan: plan, coupon_code: coupon.code).call

      expect(result).not_to be_success
      expect(result.errors).to eq("Cupom indisponível no momento.")
    end

    it "rejeita empresa que já usou cupom recentemente" do
      plan = create(:plan)
      coupon = create(:coupon)
      redemption = create(:coupon_redemption, applied_at: 1.month.ago)

      result = described_class.new(plan: plan, coupon_code: coupon.code, company: redemption.company).call

      expect(result).not_to be_success
      expect(result.errors).to eq("Sua empresa já utilizou um cupom nos últimos 12 meses.")
    end

    it "permite cupom trial com custo zero" do
      plan = create(:plan, transaction_amount: 99)
      coupon = create(:coupon, :trial)

      result = described_class.new(plan: plan, coupon_code: coupon.code, payment_method: "credit_card").call

      expect(result).to be_success
      expect(result).to be_trial
      expect(result).to be_zero_cost
    end

    it "rejeita desconto financeiro no cartão" do
      plan = create(:plan)
      coupon = create(:coupon)

      result = described_class.new(plan: plan, coupon_code: coupon.code, payment_method: "credit_card").call

      expect(result).not_to be_success
      expect(result.errors).to eq("Cupons de desconto no cartão ainda não são suportados neste fluxo.")
    end
  end
end
