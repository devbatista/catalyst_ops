require "rails_helper"

RSpec.describe Subscriptions::ExpirationWarningMailer, type: :mailer do
  describe "#warning_email" do
    it "envia aviso de vencimento com data da assinatura" do
      subscription = create(:subscription, end_date: Date.current - 5.days)

      email = described_class.with(subscription: subscription).warning_email

      expect(email.to).to eq([subscription.company.email])
      expect(email.subject).to eq("Sua assinatura CatalystOps está vencida")
      expect(email.body.encoded).to include(subscription.company.name)
      expect(email.body.encoded).to include(I18n.l(subscription.end_date))
    end
  end
end
