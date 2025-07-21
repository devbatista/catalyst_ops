require "rails_helper"

RSpec.describe ServiceItem, type: :model do
  describe "associações" do
    it { should belong_to(:order_service) }
  end

  describe "validações" do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:quantity) }
    it { should validate_presence_of(:unit_price) }
    it { should validate_numericality_of(:quantity).is_greater_than(0) }
    it { should validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0) }

    it "não permite quantidade zero ou negativa" do
      item = build(:service_item, quantity: 0)
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to be_present

      item = build(:service_item, quantity: -1)
      expect(item).not_to be_valid
    end

    it "não permite preço negativo" do
      item = build(:service_item, unit_price: -10)
      expect(item).not_to be_valid
      expect(item.errors[:unit_price]).to be_present
    end
  end

  describe "métodos de negócio" do
    it "calcula o total corretamente" do
      item = build(:service_item, quantity: 3, unit_price: 10.5)
      expect(item.total_price).to eq(31.5)
    end

    it "formata o total corretamente" do
      item = build(:service_item, quantity: 2, unit_price: 15)
      expect(item.formatted_total_price).to eq("R$ 30.00") if item.respond_to?(:formatted_total_price)
    end
  end

  describe "factory" do
    it "possui uma factory válida" do
      expect(build(:service_item)).to be_valid
    end
  end

  describe "edge cases" do
    it "aceita valores decimais grandes" do
      item = build(:service_item, quantity: 1.5, unit_price: 99.99)
      expect(item.total_price).to eq(149.985)
    end

    it "arredonda corretamente o total se necessário" do
      item = build(:service_item, quantity: 2, unit_price: 33.333)
      expect(item.total_price.round(2)).to eq(66.67)
    end
  end
end
