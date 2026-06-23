require "rails_helper"

RSpec.describe Subscriptions::ExpireOverdueSubscriptionsJob, type: :job do
  describe "#perform" do
    it "busca assinaturas expiradas e chama o command correto" do
      subscription = create(:subscription)
      command = instance_double(Cmd::Subscriptions::ExpireOverdueSubscriptions, call: expire_result(true))

      allow(Subscription).to receive(:overdue_for_expiration).and_return(Subscription.where(id: subscription.id))
      allow(Cmd::Subscriptions::ExpireOverdueSubscriptions).to receive(:new).with(subscription_id: subscription.id).and_return(command)
      allow(Rails.logger).to receive(:info)

      described_class.new.perform

      aggregate_failures do
        expect(command).to have_received(:call)
        expect(Rails.logger).to have_received(:info).with("[Subscriptions::ExpireOverdueSubscriptionsJob] Assinatura ID #{subscription.id} expirada com sucesso.")
        expect(Rails.logger).to have_received(:info).with("[Subscriptions::ExpireOverdueSubscriptionsJob] 1 assinatura(s) processada(s) para expiração.")
      end
    end

    it "registra log quando não há assinaturas expiradas" do
      allow(Subscription).to receive(:overdue_for_expiration).and_return(Subscription.none)
      allow(Rails.logger).to receive(:info)

      described_class.new.perform

      expect(Rails.logger).to have_received(:info).with("[Subscriptions::ExpireOverdueSubscriptionsJob] Nenhuma assinatura vencida há 10 dias ou mais para expirar.")
    end

    it "registra erro quando o command retorna falha" do
      subscription = create(:subscription)
      command = instance_double(Cmd::Subscriptions::ExpireOverdueSubscriptions, call: expire_result(false, "não foi possível expirar"))

      allow(Subscription).to receive(:overdue_for_expiration).and_return(Subscription.where(id: subscription.id))
      allow(Cmd::Subscriptions::ExpireOverdueSubscriptions).to receive(:new).with(subscription_id: subscription.id).and_return(command)
      allow(Rails.logger).to receive(:error)

      described_class.new.perform

      expect(Rails.logger).to have_received(:error).with("[Subscriptions::ExpireOverdueSubscriptionsJob] Falha ao expirar assinatura ID #{subscription.id}: não foi possível expirar")
    end

    it "registra erro quando o command levanta exceção" do
      subscription = create(:subscription)
      command = instance_double(Cmd::Subscriptions::ExpireOverdueSubscriptions)

      allow(Subscription).to receive(:overdue_for_expiration).and_return(Subscription.where(id: subscription.id))
      allow(Cmd::Subscriptions::ExpireOverdueSubscriptions).to receive(:new).with(subscription_id: subscription.id).and_return(command)
      allow(command).to receive(:call).and_raise(StandardError, "falha inesperada")
      allow(Rails.logger).to receive(:error)

      described_class.new.perform

      expect(Rails.logger).to have_received(:error).with("[Subscriptions::ExpireOverdueSubscriptionsJob] Erro ao expirar assinatura ID #{subscription.id}: falha inesperada")
    end
  end

  def expire_result(success, errors = nil)
    Cmd::Subscriptions::ExpireOverdueSubscriptions::Result.new(success, nil, errors)
  end
end
