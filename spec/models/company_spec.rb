require 'rails_helper'

RSpec.describe Company, type: :model do
  describe "#pdf_customization_available?" do
    it "is available for Profissional plan" do
      company = build(:company, plan: build(:plan, :profissional))

      expect(company.pdf_customization_available?).to be(true)
    end

    it "is available for Enterprise plan" do
      company = build(:company, plan: build(:plan, :enterprise))

      expect(company.pdf_customization_available?).to be(true)
    end

    it "is not available for Basico plan" do
      company = build(:company, plan: build(:plan))

      expect(company.pdf_customization_available?).to be(false)
    end

    it "is not available when company has no plan" do
      company = build(:company, plan: nil)

      expect(company.pdf_customization_available?).to be(false)
    end
  end
end
