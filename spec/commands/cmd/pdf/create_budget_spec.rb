require "rails_helper"

RSpec.describe Cmd::Pdf::CreateBudget do
  describe "#generate_pdf_data" do
    it "generates a budget PDF with default settings" do
      budget = build_budget

      pdf_data = described_class.new(budget).generate_pdf_data

      expect(pdf_data).to start_with("%PDF")
    end

    it "generates a budget PDF with customized company settings" do
      budget = build_budget
      budget.company.plan = build(:plan, :enterprise)
      setting = budget.company.pdf_settings.build(
        document_type: "budget",
        customization_enabled: true,
        accent_color: "0F766E",
        header_subtitle: "Proposta técnica",
        document_note: "Condições comerciais personalizadas.",
        footer_text: "Rodapé do orçamento",
        show_company_data: false,
        show_client_data: false,
        show_service_description: false,
        show_service_items: false
      )
      attach_logo(setting)

      pdf_data = described_class.new(budget).generate_pdf_data

      expect(pdf_data).to start_with("%PDF")
    end
  end

  def build_budget
    company = build(:company)
    client = build(:client, company: company)
    budget = build(:budget, company: company, client: client)

    budget.service_items.build(description: "Manutenção preventiva", quantity: 1, unit_price: 100)
    budget
  end

  def attach_logo(setting)
    setting.logo.attach(
      io: File.open(Rails.root.join("app/assets/images/logo-icon.png")),
      filename: "logo-icon.png",
      content_type: "image/png"
    )
  end
end
