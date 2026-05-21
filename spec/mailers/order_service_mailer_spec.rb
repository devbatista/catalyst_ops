require "rails_helper"

RSpec.describe OrderServiceMailer, type: :mailer do
  let(:plan) { create(:plan) }
  let(:company) { create(:company, plan: plan, name: "Empresa Mailer") }
  let!(:subscription) { create(:subscription, company: company, subscription_plan: plan, status: :active) }
  let(:client) { create(:client, company: company, name: "Cliente Mailer", email: "cliente@example.com") }
  let(:order_service) { create(:order_service, company: company, client: client, scheduled_at: 2.days.from_now) }

  before do
    allow(UserMailer).to receive(:welcome_email).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: true))
  end

  describe "#notify_client_on_scheduled" do
    it "envia o agendamento para o cliente da OS" do
      email = described_class.notify_client_on_scheduled(order_service)

      expect(email.to).to eq(["cliente@example.com"])
      expect(email.subject).to eq("Sua ordem de serviço foi atribuída e agendada!")
      expect(email.text_part.decoded).to include(order_service.code.to_s)
    end
  end

  describe "#notify_technical_on_scheduled" do
    it "envia a designação para o técnico" do
      technician = create(:user, :tecnico, company: company, active: true, name: "Técnico Mailer", email: "tecnico@example.com")
      create(:address, client: client, street: "Rua Técnica")

      email = described_class.notify_technical_on_scheduled(order_service, technician)

      expect(email.to).to eq(["tecnico@example.com"])
      expect(email.subject).to eq("ATENÇÃO, Você foi designado para a Ordem de Serviço ##{order_service.code}")
      expect(email.text_part.decoded).to include("Técnico Mailer", client.name, "Rua Técnica")
    end
  end
end
