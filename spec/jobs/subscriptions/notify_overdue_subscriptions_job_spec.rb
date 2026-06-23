require "rails_helper"

RSpec.describe Subscriptions::NotifyOverdueSubscriptionsJob, type: :job do
  describe "#perform" do
    it "notifica assinaturas vencidas elegíveis" do
      subscription = create(:subscription, status: :active, end_date: Date.current - 6.days, expiration_warning_sent_at: nil)
      command = instance_double(Cmd::Subscriptions::NotifySubscription, call: double(success?: true, errors: nil))

      allow(Cmd::Subscriptions::NotifySubscription).to receive(:new).with(subscription_id: subscription.id).and_return(command)
      allow(Rails.logger).to receive(:info)

      described_class.new.perform

      expect(command).to have_received(:call)
      expect(Rails.logger).to have_received(:info).with("[Subscriptions::NotifyOverdueSubscriptionsJob] Notificação de vencimento registrada para assinatura ID #{subscription.id}.")
    end

    it "registra erro sem interromper quando comando falha" do
      subscription = create(:subscription, status: :active, end_date: Date.current - 6.days, expiration_warning_sent_at: nil)
      command = instance_double(Cmd::Subscriptions::NotifySubscription, call: double(success?: false, errors: "smtp fora"))

      allow(Cmd::Subscriptions::NotifySubscription).to receive(:new).and_return(command)
      allow(Rails.logger).to receive(:error)

      described_class.new.perform

      expect(Rails.logger).to have_received(:error).with("[Subscriptions::NotifyOverdueSubscriptionsJob] Erro ao notificar assinatura ID #{subscription.id}: smtp fora")
    end

    it "registra ausência de assinaturas vencidas" do
      allow(Rails.logger).to receive(:info)

      described_class.new.perform

      expect(Rails.logger).to have_received(:info).with("[Subscriptions::NotifyOverdueSubscriptionsJob] Nenhuma assinatura vencida para notificar.")
    end
  end
end
