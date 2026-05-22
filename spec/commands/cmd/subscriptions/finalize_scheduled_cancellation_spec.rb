require "rails_helper"

RSpec.describe Cmd::Subscriptions::FinalizeScheduledCancellation do
  describe "#call" do
    let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

    before do
      allow(Subscriptions::CancellationMailer).to receive(:with).and_return(double(cancelled_email: mail_delivery))
    end

    it "retorna erro quando assinatura não existe" do
      result = described_class.new(subscription_id: SecureRandom.uuid).call

      expect(result).not_to be_success
      expect(result.errors).to eq("Assinatura não encontrada")
    end

    it "retorna erro quando cancelamento ainda não venceu" do
      subscription = create(:subscription, cancel_at_period_end: true, cancel_effective_on: Date.tomorrow)

      result = described_class.new(subscription_id: subscription.id).call

      expect(result).not_to be_success
      expect(result.errors).to eq("Assinatura ainda não está no período de cancelamento efetivo")
    end

    it "finaliza cancelamento agendado e desativa acesso da empresa" do
      subscription = create(:subscription, status: :active, cancel_at_period_end: true, cancel_effective_on: Date.current)
      company = subscription.company

      result = described_class.new(subscription_id: subscription.id).call

      expect(result).to be_success
      expect(subscription.reload).to be_cancelled
      expect(subscription.cancel_at_period_end).to be false
      expect(company.reload).not_to be_active
      expect(mail_delivery).to have_received(:deliver_later)
    end

    it "cancela assinatura no gateway quando pagamento é cartão" do
      company = create(:company, payment_method: "credit_card")
      subscription = create(
        :subscription,
        company: company,
        status: :active,
        cancel_at_period_end: true,
        cancel_effective_on: Date.current,
        external_subscription_id: "pre_123"
      )
      command = instance_double(Cmd::MercadoPago::CancelCreditCardSubscription, call: double(success?: true, errors: nil))

      allow(Cmd::MercadoPago::CancelCreditCardSubscription).to receive(:new).with(subscription).and_return(command)

      result = described_class.new(subscription_id: subscription.id).call

      expect(result).to be_success
      expect(command).to have_received(:call)
    end

    it "retorna falha quando cancelamento no gateway falha" do
      company = create(:company, payment_method: "credit_card")
      subscription = create(
        :subscription,
        company: company,
        status: :active,
        cancel_at_period_end: true,
        cancel_effective_on: Date.current,
        external_subscription_id: "pre_123"
      )
      command = instance_double(Cmd::MercadoPago::CancelCreditCardSubscription, call: double(success?: false, errors: "erro externo"))

      allow(Cmd::MercadoPago::CancelCreditCardSubscription).to receive(:new).with(subscription).and_return(command)

      result = described_class.new(subscription_id: subscription.id).call

      expect(result).not_to be_success
      expect(result.errors).to eq("Falha ao cancelar assinatura no gateway: erro externo")
      expect(subscription.reload).to be_active
    end
  end
end
