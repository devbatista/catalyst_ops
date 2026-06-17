require "rails_helper"

RSpec.describe Coupons::Redeem do
  describe ".call" do
    it "retorna nil quando não há cupom" do
      result = described_class.call(
        coupon: nil,
        company: create(:company),
        subscription: create(:subscription),
        original_amount: 100,
        final_amount: 90
      )

      expect(result).to be_nil
    end

    it "cria resgate com valores calculados" do
      coupon = create(:coupon)
      subscription = create(:subscription)

      redemption = described_class.call(
        coupon: coupon,
        company: subscription.company,
        subscription: subscription,
        original_amount: 100,
        final_amount: 80,
        applied_at: Time.zone.local(2026, 5, 22, 10, 0, 0)
      )

      aggregate_failures do
        expect(redemption).to be_persisted
        expect(redemption.coupon).to eq(coupon)
        expect(redemption.company).to eq(subscription.company)
        expect(redemption.original_amount).to eq(100)
        expect(redemption.discount_amount).to eq(20)
        expect(redemption.final_amount).to eq(80)
      end
    end

    it "reutiliza o resgate existente da assinatura" do
      coupon = create(:coupon)
      subscription = create(:subscription)
      existing = create(:coupon_redemption, subscription: subscription, company: subscription.company, applied_at: 13.months.ago)

      redemption = described_class.call(
        coupon: coupon,
        company: subscription.company,
        subscription: subscription,
        original_amount: 200,
        final_amount: 150
      )

      expect(redemption.id).to eq(existing.id)
      expect(redemption.reload.discount_amount).to eq(50)
    end

    it "propaga erro quando empresa já usou cupom no último ano" do
      existing = create(:coupon_redemption, applied_at: 1.month.ago)
      subscription = create(:subscription, company: existing.company)

      expect do
        described_class.call(
          coupon: create(:coupon),
          company: existing.company,
          subscription: subscription,
          original_amount: 100,
          final_amount: 90
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
