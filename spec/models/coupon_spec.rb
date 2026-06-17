require "rails_helper"

RSpec.describe Coupon, type: :model do
  describe "associações" do
    it { should have_many(:coupon_redemptions).dependent(:restrict_with_exception) }
  end

  describe "validações" do
    subject(:coupon) { build(:coupon) }

    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code).case_insensitive }
    it { should validate_presence_of(:name) }
    it { should validate_inclusion_of(:benefit_type).in_array(Coupon::BENEFIT_TYPES) }
    it { should validate_inclusion_of(:discount_type).in_array(Coupon::DISCOUNT_TYPES).allow_blank }
    it { should validate_inclusion_of(:trial_frequency_type).in_array(Coupon::FREQUENCY_TYPES).allow_blank }
    it { should validate_numericality_of(:discount_value).is_greater_than(0).allow_nil }
    it { should validate_numericality_of(:max_redemptions).only_integer.is_greater_than(0).allow_nil }

    it "normaliza código antes de validar" do
      coupon = build(:coupon, code: " promo10 ")

      coupon.valid?

      expect(coupon.code).to eq("PROMO10")
    end

    it "exige configuração financeira em cupom de desconto" do
      coupon = build(:coupon, benefit_type: "discount", discount_type: nil, discount_value: nil)

      expect(coupon).not_to be_valid
      expect(coupon.errors[:base]).to include("Cupons de desconto precisam informar tipo e valor do desconto.")
    end

    it "não permite desconto percentual maior que 100" do
      coupon = build(:coupon, discount_type: "percentage", discount_value: 101)

      expect(coupon).not_to be_valid
      expect(coupon.errors[:discount_value]).to include("não pode ser maior que 100 para cupons percentuais")
    end

    it "exige duração em cupom de teste" do
      coupon = build(:coupon, :trial, trial_frequency: nil, trial_frequency_type: nil)

      expect(coupon).not_to be_valid
      expect(coupon.errors[:base]).to include("Cupons de teste precisam informar a duração do período de teste.")
    end

    it "não permite desconto financeiro em cupom de teste" do
      coupon = build(:coupon, :trial, discount_type: "percentage", discount_value: 10)

      expect(coupon).not_to be_valid
      expect(coupon.errors[:base]).to include("Cupons de teste não devem definir desconto financeiro.")
    end

    it "exige data final posterior à inicial" do
      coupon = build(:coupon, valid_from: 1.day.from_now, valid_until: 1.day.ago)

      expect(coupon).not_to be_valid
      expect(coupon.errors[:valid_until]).to include("deve ser posterior à data inicial")
    end
  end

  describe "regras de elegibilidade" do
    it "fica disponível quando ativo, iniciado, não expirado e com resgates disponíveis" do
      expect(build(:coupon)).to be_available
    end

    it "não fica disponível quando expirado" do
      expect(build(:coupon, valid_until: 1.minute.ago)).not_to be_available
    end

    it "calcula resgates restantes" do
      coupon = build(:coupon, max_redemptions: 3, redemptions_count: 1)

      expect(coupon.remaining_redemptions).to eq(2)
    end

    it "calcula desconto percentual limitado ao valor original" do
      coupon = build(:coupon, discount_type: "percentage", discount_value: 20)

      expect(coupon.calculate_discount(100)).to eq(20)
      expect(coupon.calculate_final_amount(100)).to eq(80)
    end

    it "calcula desconto fixo limitado ao valor original" do
      coupon = build(:coupon, :fixed_amount, discount_value: 150)

      expect(coupon.calculate_discount(100)).to eq(100)
      expect(coupon.calculate_final_amount(100)).to eq(0)
    end
  end
end
