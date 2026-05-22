require "rails_helper"

RSpec.describe Payments::CreditCardMailer, type: :mailer do
  describe "#credit_card_email" do
    it "envia cobrança para o e-mail da empresa" do
      company = build(:company, email: "empresa@example.com")
      plan = build(:plan, name: "Profissional")

      email = described_class.with(company: company, plan: plan, payment_url: "https://pagamento").credit_card_email

      expect(email.to).to eq(["empresa@example.com"])
      expect(email.subject).to eq("Seu código PIX CatalystOps")
      expect(email.body.encoded).to include("https://pagamento")
      expect(email.body.encoded).to include("Profissional")
    end
  end
end
