require "rails_helper"

RSpec.describe "Commands auxiliares" do
  describe Cmd::Companies::Create do
    it "salva empresa válida" do
      company = build(:company)

      result = described_class.new(company).call

      aggregate_failures do
        expect(result).to be_success
        expect(company).to be_persisted
      end
    end

    it "retorna erros para empresa inválida" do
      company = build(:company, name: "")

      result = described_class.new(company).call

      expect(result.errors).to be_present
    end
  end

  describe Cmd::Users::Create do
    it "salva usuário válido" do
      user = build(:user)
      mail = instance_double(ActionMailer::MessageDelivery, deliver_later: true)

      allow(UserMailer).to receive(:welcome_email).and_return(mail)

      result = described_class.new(user).call

      aggregate_failures do
        expect(result).to be_success
        expect(user).to be_persisted
      end
    end

    it "retorna erros para usuário inválido" do
      user = build(:user, email: "")

      result = described_class.new(user).call

      expect(result.errors).to be_present
    end
  end

  describe Cmd::MercadoPago::SyncPlans do
    it "sincroniza planos retornados pelo Mercado Pago e remove ausentes" do
      stale_plan = create(:plan, external_id: "stale")
      client = instance_double(MercadoPago::Client, fetch_plans: [plan_payload("plan_sync")])

      described_class.new(client: client).call

      aggregate_failures do
        expect(Plan.exists?(stale_plan.id)).to be(false)
        expect(Plan.find_by(external_id: "plan_sync")).to have_attributes(
          name: "Profissional",
          reason: "c-profissional",
          status: "active",
          external_reference: "PROFISSIONAL",
          frequency: 1,
          frequency_type: "months"
        )
      end
    end

    def plan_payload(id)
      {
        "id" => id,
        "reason" => "c-profissional",
        "status" => "active",
        "external_reference" => "PROFISSIONAL",
        "auto_recurring" => {
          "frequency" => 1,
          "frequency_type" => "months",
          "transaction_amount" => 199.0
        }
      }
    end
  end
end
