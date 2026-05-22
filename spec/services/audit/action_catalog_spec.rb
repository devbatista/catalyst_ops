require "rails_helper"

RSpec.describe Audit::ActionCatalog do
  describe ".include?" do
    it "retorna true para ações catalogadas" do
      expect(described_class.include?("coupon.applied")).to be true
    end

    it "retorna false para ações desconhecidas" do
      expect(described_class.include?("coupon.unknown")).to be false
    end
  end

  it "mantém todos os grupos no catálogo consolidado" do
    expect(described_class::ALL).to include(*described_class::GROUPS.values.flatten)
  end
end
