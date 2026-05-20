require "rails_helper"

RSpec.describe Subscriptions::PixMailer, type: :mailer do
  describe "#pix_email" do
    it "envia PIX de renovação para a empresa" do
      company = create(:company, email: "financeiro@example.com")

      mail = described_class.with(
        company: company,
        pix_code: "codigo-renovacao",
        pix_image_url: "imagem",
        pix_expiration_date: "2026-05-27",
        pix_ticket_url: "https://pix-renovacao.example"
      ).pix_email

      aggregate_failures do
        expect(mail.to).to eq(["financeiro@example.com"])
        expect(mail.subject).to eq("Receba seu código pix para a renovação do CatalystOps")
        expect(mail.body.encoded).to include("codigo-renovacao")
      end
    end
  end
end
