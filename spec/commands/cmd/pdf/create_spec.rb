require "rails_helper"

RSpec.describe Cmd::Pdf::Create do
  describe "#generate_pdf_data" do
    it "generates a PDF with default settings" do
      order_service = build_order_service

      pdf_data = described_class.new(order_service).generate_pdf_data

      expect(pdf_data).to start_with("%PDF")
    end

    it "generates a PDF with customized company settings" do
      order_service = build_order_service
      order_service.company.plan = build(:plan, :profissional)
      order_service.company.pdf_settings.build(
        document_type: "order_service",
        customization_enabled: true,
        accent_color: "0F766E",
        header_subtitle: "Atendimento técnico",
        document_note: "Documento personalizado da empresa.",
        footer_text: "Rodapé personalizado",
        show_company_data: false,
        show_client_data: false,
        show_service_description: false,
        show_service_items: false,
        show_observations: false,
        show_discount_reason: false
      )

      pdf_data = described_class.new(order_service).generate_pdf_data

      expect(pdf_data).to start_with("%PDF")
    end
  end

  def build_order_service
    company = build(:company)
    client = build(:client, company: company)
    order_service = build(
      :order_service,
      company: company,
      client: client,
      expected_end_at: 2.days.from_now,
      observations: "Observação interna"
    )

    order_service.service_items.build(description: "Instalação", quantity: 1, unit_price: 100)
    order_service
  end
end
