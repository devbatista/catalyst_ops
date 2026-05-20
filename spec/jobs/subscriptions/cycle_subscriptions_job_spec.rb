require "rails_helper"

RSpec.describe Subscriptions::CycleSubscriptionsJob, type: :job do
  describe "#perform" do
    it "executa o command para cada assinatura apta" do
      first_subscription = create(:subscription)
      second_subscription = create(:subscription)
      first_command = instance_double(Cmd::Subscriptions::CycleSubscription, call: true)
      second_command = instance_double(Cmd::Subscriptions::CycleSubscription, call: true)

      allow(Subscription).to receive(:ready_to_cycle).and_return(Subscription.where(id: [first_subscription.id, second_subscription.id]))
      allow(Cmd::Subscriptions::CycleSubscription)
        .to receive(:new)
        .with(subscription_id: first_subscription.id)
        .and_return(first_command)
      allow(Cmd::Subscriptions::CycleSubscription)
        .to receive(:new)
        .with(subscription_id: second_subscription.id)
        .and_return(second_command)
      allow(Rails.logger).to receive(:info)

      described_class.new.perform

      aggregate_failures do
        expect(first_command).to have_received(:call)
        expect(second_command).to have_received(:call)
        expect(Rails.logger).to have_received(:info).with("[Subscriptions::CycleSubscriptionsJob] Assinatura ID #{first_subscription.id} ciclada com sucesso.")
        expect(Rails.logger).to have_received(:info).with("[Subscriptions::CycleSubscriptionsJob] Assinatura ID #{second_subscription.id} ciclada com sucesso.")
      end
    end

    it "registra log quando não há assinaturas aptas" do
      allow(Subscription).to receive(:ready_to_cycle).and_return(Subscription.none)
      allow(Rails.logger).to receive(:info)

      described_class.new.perform

      expect(Rails.logger).to have_received(:info).with("[Subscriptions::CycleSubscriptionsJob] Nenhuma assinatura para renovar.")
    end

    it "registra erro quando uma assinatura falha no processamento" do
      subscription = create(:subscription)
      error = StandardError.new("falha no gateway")
      command = instance_double(Cmd::Subscriptions::CycleSubscription)

      allow(Subscription).to receive(:ready_to_cycle).and_return(Subscription.where(id: subscription.id))
      allow(Cmd::Subscriptions::CycleSubscription).to receive(:new).with(subscription_id: subscription.id).and_return(command)
      allow(command).to receive(:call).and_raise(error)
      allow(Rails.logger).to receive(:error)

      described_class.new.perform

      expect(Rails.logger).to have_received(:error).with("[Subscriptions::CycleSubscriptionsJob] Erro ao ciclar assinatura ID #{subscription.id}: falha no gateway")
    end
  end
end
