require "rails_helper"

RSpec.describe Payments::BoletoMailer, type: :mailer do
  describe "#ticket_email" do
    it "envia boleto para o e-mail da empresa" do
      company = create(:company, email: "financeiro@example.com")

      mail = described_class.with(
        company: company,
        boleto_url: "https://boleto.example",
        boleto_barcode: "123456",
        boleto_expiration_date: "2026-05-27",
        payment_status: "pending"
      ).ticket_email

      aggregate_failures do
        expect(mail.to).to eq(["financeiro@example.com"])
        expect(mail.subject).to eq("Seu boleto CatalystOps")
        expect(mail.body.encoded).to include("https://boleto.example")
        expect(mail.body.encoded).to include("123456")
      end
    end
  end
end
