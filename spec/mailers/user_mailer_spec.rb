require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:user) { build(:user, name: "Maria Usuária", email: "maria@example.com") }

  before do
    Rails.application.routes.default_url_options[:host] = "example.com"
  end

  describe "#welcome_email" do
    it "envia link de definição de senha para o usuário" do
      email = described_class.welcome_email(user, "reset-token")

      expect(email.to).to eq(["maria@example.com"])
      expect(email.subject).to eq("Sua conta no CatalystOps foi criada!")
      expect(email.body.decoded).to include("Maria Usuária", "reset_password_token=reset-token")
    end
  end

  describe "#signup_confirmation_email" do
    it "envia link de confirmação de cadastro" do
      email = described_class.signup_confirmation_email(user, "confirmation-token")

      expect(email.to).to eq(["maria@example.com"])
      expect(email.subject).to eq("Confirme seu cadastro no CatalystOps")
      expect(email.text_part.decoded).to include("Maria Usuária", "token=confirmation-token")
    end
  end

  describe "#reset_password_email" do
    it "envia link de redefinição de senha" do
      email = described_class.reset_password_email(user, "reset-token")

      expect(email.to).to eq(["maria@example.com"])
      expect(email.subject).to eq("Redefinição de senha - CatalystOps")
      expect(email.text_part.decoded).to include("reset_password_token=reset-token")
    end
  end
end
