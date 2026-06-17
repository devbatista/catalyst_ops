require "rails_helper"

RSpec.describe Audit::AuthLogger do
  before do
    allow(Audit::Log).to receive(:call)
  end

  it "registra login bem-sucedido" do
    user = build_stubbed(:user, :gestor)

    described_class.login_succeeded(user: user)

    expect(Audit::Log).to have_received(:call).with(
      action: "auth.login.succeeded",
      actor: user,
      company: user.company,
      metadata: hash_including(user_id: user.id, role: "gestor", email: user.email)
    )
  end

  it "registra falha por usuário inexistente" do
    described_class.login_failed(email: "naoexiste@example.com", user: nil)

    expect(Audit::Log).to have_received(:call).with(
      action: "auth.login.failed",
      actor: nil,
      company: nil,
      metadata: { email: "naoexiste@example.com", reason: "user_not_found" }
    )
  end

  it "registra logout" do
    user = build_stubbed(:user, :gestor)

    described_class.logout_succeeded(user: user)

    expect(Audit::Log).to have_received(:call).with(
      action: "auth.logout.succeeded",
      actor: user,
      company: user.company,
      metadata: hash_including(user_id: user.id, email: user.email)
    )
  end
end
