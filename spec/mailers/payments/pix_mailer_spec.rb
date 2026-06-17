require "rails_helper"

RSpec.describe Payments::PixMailer, type: :mailer do
  describe "#pix_email" do
    it "envia PIX para empresa e responsável sem duplicar e-mails" do
      company = create(:company, email: "financeiro@example.com")
      responsible = create(:user, :gestor, company: company, email: "gestor@example.com")
      company.update!(responsible: responsible)

      mail = described_class.with(
        company: company,
        pix_code: "codigo-pix",
        pix_image_url: "imagem",
        pix_expiration_date: "2026-05-27",
        pix_ticket_url: "https://pix.example"
      ).pix_email

      aggregate_failures do
        expect(mail.to).to contain_exactly("financeiro@example.com", "gestor@example.com")
        expect(mail.subject).to eq("Seu código PIX CatalystOps")
        expect(mail.body.encoded).to include("codigo-pix")
      end
    end
  end
end
