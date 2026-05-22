require "rails_helper"

RSpec.describe Subscriptions::CancellationMailer, type: :mailer do
  describe "#requested_email" do
    it "envia solicitação de cancelamento para responsável" do
      subscription = subscription_with_responsible
      subscription.update!(cancel_requested_at: Time.current, cancel_effective_on: Date.current + 7.days, cancel_reason: "Sem uso")

      email = described_class.with(subscription: subscription).requested_email

      expect(email.to).to eq([subscription.company.responsible.email])
      expect(email.subject).to include("Solicitação de cancelamento")
      expect(email.body.encoded).to include("Sem uso")
      expect(email.body.encoded).to include(subscription.company.name)
    end
  end

  describe "#cancelled_email" do
    it "envia confirmação de cancelamento" do
      subscription = subscription_with_responsible
      subscription.update!(canceled_date: Time.current)

      email = described_class.with(subscription: subscription).cancelled_email

      expect(email.to).to eq([subscription.company.responsible.email])
      expect(email.subject).to include("Assinatura cancelada")
      expect(email.body.encoded).to include(subscription.company.name)
    end
  end

  describe "#reactivated_email" do
    it "envia aviso de reativação" do
      subscription = subscription_with_responsible

      email = described_class.with(subscription: subscription).reactivated_email

      expect(email.to).to eq([subscription.company.responsible.email])
      expect(email.subject).to include("Renovação da assinatura reativada")
      expect(email.body.encoded).to include(subscription.company.name)
    end
  end

  def subscription_with_responsible
    plan = create(:plan)
    responsible = create(:user, :gestor, email: "responsavel@example.com")
    company = create(:company, plan: plan, responsible: responsible)
    responsible.update!(company: company)
    create(:subscription, company: company, subscription_plan: plan)
  end
end
