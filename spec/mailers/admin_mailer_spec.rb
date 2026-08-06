require "rails_helper"

RSpec.describe AdminMailer, type: :mailer do
  describe "#test_email" do
    it "envia e-mail de teste para o destinatário informado" do
      admin = build(:user, :admin, name: "Admin Teste", email: "admin@example.com")

      email = described_class.test_email("destino@example.com", admin)

      aggregate_failures do
        expect(email.to).to eq(["destino@example.com"])
        expect(email.subject).to eq("E-mail de teste - CatalystOps")
        expect(email.text_part.decoded).to include("destino@example.com", "Admin Teste", "admin@example.com")
      end
    end
  end
end
