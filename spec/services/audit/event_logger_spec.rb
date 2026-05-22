require "rails_helper"

RSpec.describe Audit::EventLogger do
  describe ".call" do
    it "cria evento com ator, empresa, recurso e metadados normalizados" do
      company = create(:company)
      actor = create(:user, :gestor, company: company)
      plan = create(:plan)

      event = described_class.call(
        action: "plan.updated",
        source: "admin",
        actor: actor,
        resource: plan,
        metadata: "alterado",
        request_id: "req-1",
        ip_address: "127.0.0.1",
        user_agent: "RSpec"
      )

      aggregate_failures do
        expect(event).to be_persisted
        expect(event.company).to eq(company)
        expect(event.actor_type).to eq("User")
        expect(event.actor_id).to eq(actor.id)
        expect(event.resource_type).to eq("Plan")
        expect(event.resource_id).to eq(plan.id)
        expect(event.metadata).to eq("value" => "alterado")
      end
    end
  end
end
