require "rails_helper"

RSpec.describe CouponRedemption, type: :model do
  describe "associações" do
    it { should belong_to(:coupon).counter_cache(:redemptions_count) }
    it { should belong_to(:company) }
    it { should belong_to(:subscription) }
  end

  describe "validações" do
    subject(:redemption) { build(:coupon_redemption) }

    it { should validate_uniqueness_of(:subscription_id) }
    it { should validate_presence_of(:original_amount) }
    it { should validate_presence_of(:discount_amount) }
    it { should validate_presence_of(:final_amount) }
    it { should validate_presence_of(:applied_at) }

    it "não permite final maior que valor original" do
      redemption = build(:coupon_redemption, original_amount: 100, final_amount: 101)

      expect(redemption).not_to be_valid
      expect(redemption.errors[:final_amount]).to include("não pode ser maior que o valor original")
    end

    it "não permite desconto maior que valor original" do
      redemption = build(:coupon_redemption, original_amount: 100, discount_amount: 101)

      expect(redemption).not_to be_valid
      expect(redemption.errors[:discount_amount]).to include("não pode ser maior que o valor original")
    end

    it "não permite novo resgate da mesma empresa dentro de 12 meses" do
      existing = create(:coupon_redemption, applied_at: 1.month.ago)
      subscription = create(:subscription, company: existing.company)
      redemption = build(:coupon_redemption, company: existing.company, subscription: subscription, applied_at: Time.current)

      expect(redemption).not_to be_valid
      expect(redemption.errors[:base]).to include("A empresa já utilizou um cupom nos últimos 12 meses.")
    end
  end

  describe ".used_by_company_within_last_year?" do
    it "retorna true quando há resgate recente" do
      redemption = create(:coupon_redemption, applied_at: 6.months.ago)

      expect(described_class.used_by_company_within_last_year?(redemption.company)).to be true
    end

    it "retorna false sem empresa" do
      expect(described_class.used_by_company_within_last_year?(nil)).to be false
    end
  end
end
