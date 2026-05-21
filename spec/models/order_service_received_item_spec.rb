require "rails_helper"

RSpec.describe OrderServiceReceivedItem, type: :model do
  describe "associações" do
    it { should belong_to(:order_service) }
  end

  describe "validações" do
    subject(:received_item) { build(:order_service_received_item) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(120) }
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than(0).is_less_than_or_equal_to(9999).allow_nil }
    it { should validate_length_of(:brand).is_at_most(120) }
    it { should validate_length_of(:model).is_at_most(120) }
    it { should validate_length_of(:serial_number).is_at_most(120) }
  end

  describe "regras de recebimento" do
    it "permite quantidade em branco" do
      item = build(:order_service_received_item, quantity: nil)

      expect(item).to be_valid
    end

    it "não permite quantidade zero" do
      item = build(:order_service_received_item, quantity: 0)

      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include("deve ser maior que 0")
    end
  end

  describe "factory" do
    it "possui uma factory válida" do
      expect(build(:order_service_received_item)).to be_valid
    end
  end
end
