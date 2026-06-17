require "rails_helper"

RSpec.describe Subscriptions::BoletoMailer, type: :mailer do
  describe "#ticket_email" do
    it "envia boleto de renovação para a empresa" do
      company = create(:company, email: "financeiro@example.com")

      mail = described_class.with(
        company: company,
        boleto_url: "https://boleto-renovacao.example",
        boleto_barcode: "654321",
        boleto_expiration_date: "2026-05-27",
        payment_status: "pending"
      ).ticket_email

      aggregate_failures do
        expect(mail.to).to eq(["financeiro@example.com"])
        expect(mail.subject).to eq("Receba seu boleto para a renovação do CatalystOps")
        expect(mail.body.encoded).to include("https://boleto-renovacao.example")
      end
    end
  end
end
