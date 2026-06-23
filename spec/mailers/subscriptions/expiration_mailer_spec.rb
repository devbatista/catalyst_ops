require "rails_helper"

RSpec.describe Subscriptions::ExpirationMailer, type: :mailer do
  describe "#expired_email" do
    it "envia aviso de expiração para responsável" do
      plan = create(:plan, name: "Plano Pro")
      responsible = create(:user, :gestor, email: "responsavel@example.com")
      company = create(:company, name: "Empresa Teste", plan: plan, responsible: responsible)
      responsible.update!(company: company)
      subscription = create(:subscription, company: company, subscription_plan: plan, status: :expired, expired_date: Date.current)

      email = described_class.with(subscription: subscription).expired_email

      expect(email.to).to eq(["responsavel@example.com"])
      expect(email.subject).to eq("Assinatura expirada - Empresa Teste")
      expect(email.body.encoded).to include("Empresa Teste")
      expect(email.body.encoded).to include("Plano Pro")
      expect(email.body.encoded).to include("regulariza")
    end
  end
end
