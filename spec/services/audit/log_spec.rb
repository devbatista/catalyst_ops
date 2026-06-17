require "rails_helper"

RSpec.describe Audit::Log do
  before do
    Current.reset
  end

  after do
    Current.reset
  end

  describe ".call" do
    it "padroniza metadados e delega para o EventLogger" do
      company = create(:company)
      user = create(:user, :gestor, company: company)
      plan = create(:plan)

      Current.user = user
      Current.source = "admin"
      Current.request_id = "req-1"
      Current.ip_address = "127.0.0.1"
      Current.user_agent = "RSpec"

      allow(Audit::EventLogger).to receive(:call)

      described_class.call(action: "plan.updated", resource: plan, metadata: { campo: "name" })

      expect(Audit::EventLogger).to have_received(:call).with(
        action: "plan.updated",
        source: "admin",
        actor: user,
        company: company,
        resource: plan,
        metadata: hash_including(
          "schema_version" => 1,
          "action" => "plan.updated",
          "source" => "admin",
          "request_id" => "req-1",
          "details" => { "campo" => "name" }
        ),
        request_id: "req-1",
        ip_address: "127.0.0.1",
        user_agent: "RSpec"
      )
    end

    it "não levanta erro quando o logger falha" do
      allow(Audit::EventLogger).to receive(:call).and_raise(StandardError, "falha")
      allow(Rails.logger).to receive(:error)

      expect(described_class.call(action: "plan.updated")).to be_nil
      expect(Rails.logger).to have_received(:error).with("[Audit::Log] Falha ao registrar plan.updated: falha")
    end
  end
end
