require "rails_helper"

RSpec.describe Cmd::MercadoPago::CancelCreditCardSubscription do
  describe "#call" do
    it "retorna erro sem assinatura" do
      result = described_class.new(nil).call

      expect(result).not_to be_success
      expect(result.errors).to eq("Assinatura não encontrada")
    end

    it "retorna erro quando assinatura não tem identificador externo" do
      subscription = create(:subscription, external_subscription_id: nil)

      result = described_class.new(subscription).call

      expect(result).not_to be_success
      expect(result.errors).to eq("Assinatura sem external_subscription_id")
    end

    it "fora de produção retorna payload mockado de cancelamento" do
      subscription = create(:subscription, external_subscription_id: "pre_123")

      allow(Rails.env).to receive(:production?).and_return(false)

      result = described_class.new(subscription).call

      expect(result).to be_success
      expect(result.payload).to include("id" => "pre_123", "status" => "cancelled")
    end

    it "em produção envia cancelamento para API" do
      subscription = create(:subscription, external_subscription_id: "pre_123")
      client = instance_double(MercadoPago::Client)
      response = { "id" => "pre_123", "status" => "cancelled" }

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(MercadoPago::Client).to receive(:new).and_return(client)
      allow(client).to receive(:request).and_return(response)

      result = described_class.new(subscription).call

      expect(result).to be_success
      expect(client).to have_received(:request).with(
        method: :put,
        path: "/preapproval/pre_123",
        body: { status: "cancelled" }
      )
    end

    it "retorna falha quando a integração levanta erro" do
      subscription = create(:subscription, external_subscription_id: "pre_123")
      client = instance_double(MercadoPago::Client)

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(MercadoPago::Client).to receive(:new).and_return(client)
      allow(client).to receive(:request).and_raise(StandardError, "erro externo")
      allow(Rails.logger).to receive(:error)

      result = described_class.new(subscription).call

      expect(result).not_to be_success
      expect(result.errors).to eq("erro externo")
    end
  end
end
