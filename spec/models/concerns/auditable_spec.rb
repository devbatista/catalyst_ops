require "rails_helper"

RSpec.describe Auditable, type: :model do
  before do
    allow(Audit::Log).to receive(:call)
  end

  it "registra auditoria de criação com metadados do recurso" do
    plan = create(:plan)

    expect(Audit::Log).to have_received(:call).with(
      action: "plan.created",
      resource: plan,
      metadata: hash_including(
        event: "created",
        model: "Plan",
        plan_id: plan.id,
        action_source: "plan.created"
      )
    )
  end

  it "registra auditoria de atualização quando há mudanças relevantes" do
    plan = create(:plan)
    allow(Audit::Log).to receive(:call)

    plan.update!(name: "Profissional")

    expect(Audit::Log).to have_received(:call).with(
      action: "plan.updated",
      resource: plan,
      metadata: hash_including(
        event: "updated",
        changes: hash_including("name" => ["Basico", "Profissional"])
      )
    )
  end

  it "registra auditoria de remoção quando a ação está no catálogo" do
    plan = create(:plan)
    allow(Audit::Log).to receive(:call)

    plan.destroy!

    expect(Audit::Log).to have_received(:call).with(
      action: "plan.deleted",
      resource: plan,
      metadata: hash_including(event: "deleted", plan_id: plan.id)
    )
  end
end
