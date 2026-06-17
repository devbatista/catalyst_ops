require "rails_helper"

RSpec.describe Cmd::Subscriptions::ExpireOverdueSubscriptions do
  describe "#call" do
    it "retorna falha quando assinatura não existe" do
      result = described_class.new(subscription_id: SecureRandom.uuid).call

      aggregate_failures do
        expect(result).not_to be_success
        expect(result.subscription).to be_nil
        expect(result.errors).to eq("Assinatura não encontrada")
      end
    end

    it "expira assinatura com sucesso" do
      subscription = create(:subscription, status: :active)

      result = described_class.new(subscription_id: subscription.id).call

      aggregate_failures do
        expect(result).to be_success
        expect(result.subscription).to eq(subscription)
        expect(subscription.reload).to be_expired
        expect(subscription.expired_date).to be_present
      end
    end

    it "retorna sucesso quando assinatura já está expirada" do
      subscription = create(:subscription, status: :expired, expired_date: Time.current)

      result = described_class.new(subscription_id: subscription.id).call

      aggregate_failures do
        expect(result).to be_success
        expect(result.subscription).to eq(subscription)
      end
    end

    it "retorna falha quando ocorre exceção dentro da transação" do
      subscription = create(:subscription, status: :active)

      allow_any_instance_of(Subscription).to receive(:expire!).and_raise(StandardError, "falha ao expirar")

      result = described_class.new(subscription_id: subscription.id).call

      aggregate_failures do
        expect(result).not_to be_success
        expect(result.subscription).to eq(subscription)
        expect(result.errors).to eq("falha ao expirar")
        expect(subscription.reload).to be_active
      end
    end
  end
end
