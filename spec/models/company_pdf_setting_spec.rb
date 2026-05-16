require "rails_helper"

RSpec.describe CompanyPdfSetting, type: :model do
  subject(:setting) { build(:company_pdf_setting) }

  it { is_expected.to belong_to(:company) }
  it { is_expected.to validate_length_of(:header_subtitle).is_at_most(80) }
  it { is_expected.to validate_length_of(:document_note).is_at_most(160) }
  it { is_expected.to validate_length_of(:footer_text).is_at_most(120) }

  it "normalizes accent color before validation" do
    setting.accent_color = "#abcdef"

    setting.valid?

    expect(setting.accent_color).to eq("ABCDEF")
  end

  it "uses the default accent color when blank" do
    setting.accent_color = ""

    setting.valid?

    expect(setting.accent_color).to eq("1F6FEB")
  end

  it "rejects invalid accent colors" do
    setting.accent_color = "blue"

    expect(setting).not_to be_valid
    expect(setting.errors[:accent_color]).to include("deve ser uma cor hexadecimal valida")
  end
end
