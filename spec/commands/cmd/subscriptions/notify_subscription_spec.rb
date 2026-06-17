require "rails_helper"

RSpec.describe Cmd::Subscriptions::NotifySubscription do
  describe "#call" do
    let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

    before do
      allow(Subscriptions::ExpirationWarningMailer).to receive(:with).and_return(double(warning_email: mail_delivery))
    end

    it "retorna erro quando assinatura não existe" do
      result = described_class.new(subscription_id: SecureRandom.uuid).call

      expect(result).not_to be_success
      expect(result.errors).to eq("Assinatura não encontrada")
    end

    it "retorna erro quando assinatura já foi notificada" do
      subscription = create(:subscription, expiration_warning_sent_at: 1.day.ago)

      result = described_class.new(subscription_id: subscription.id).call

      expect(result).not_to be_success
      expect(result.errors).to eq("Assinatura já notificada")
    end

    it "envia aviso e marca data de notificação" do
      subscription = create(:subscription, expiration_warning_sent_at: nil)

      result = described_class.new(subscription_id: subscription.id).call

      expect(result).to be_success
      expect(mail_delivery).to have_received(:deliver_later)
      expect(subscription.reload.expiration_warning_sent_at).to be_present
    end

    it "retorna falha quando mailer levanta erro" do
      subscription = create(:subscription, expiration_warning_sent_at: nil)

      allow(mail_delivery).to receive(:deliver_later).and_raise(StandardError, "smtp fora")

      result = described_class.new(subscription_id: subscription.id).call

      expect(result).not_to be_success
      expect(result.errors).to eq("smtp fora")
      expect(subscription.reload.expiration_warning_sent_at).to be_nil
    end
  end
end
