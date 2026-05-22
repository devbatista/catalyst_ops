require "rails_helper"

RSpec.describe "SessionsController", type: :request do
  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    host! scoped_host_for("login")
    allow(Audit::AuthLogger).to receive(:login_succeeded)
    allow(Audit::AuthLogger).to receive(:login_failed)
    allow(Audit::AuthLogger).to receive(:logout_succeeded)
  end

  it "autentica admin e redireciona para subdomínio admin" do
    admin = create(:user, :admin, active: true, password: "Password@123")

    post "/login", params: { email: admin.email.upcase, password: "Password@123" }

    expect(response).to redirect_to(admin_dashboard_url(subdomain: "admin"))
    expect(Audit::AuthLogger).to have_received(:login_succeeded).with(user: admin)
  end

  it "autentica gestor e redireciona para app" do
    company = active_company
    user = create(:user, :gestor, company: company, active: true, password: "Password@123")

    post "/login", params: { email: user.email, password: "Password@123" }

    expect(response).to redirect_to(app_dashboard_url(subdomain: "app"))
  end

  it "rejeita credenciais inválidas" do
    post "/login", params: { email: "x@example.com", password: "errada" }

    expect(response).to redirect_to(login_root_url(subdomain: "login"))
    expect(Audit::AuthLogger).to have_received(:login_failed).with(email: "x@example.com", user: nil)
  end

  it "encerra sessão" do
    user = create(:user, :admin, active: true)
    sign_in user

    delete "/logout"

    expect(response).to redirect_to(login_root_url(subdomain: "login"))
    expect(Audit::AuthLogger).to have_received(:logout_succeeded).with(user: user)
  end

  def active_company
    plan = create(:plan)
    company = create(:company, plan: plan, active: true, terms_version_accepted: TermsOfUse.current_version, terms_accepted_at: Time.current)
    create(:subscription, company: company, subscription_plan: plan, status: :active)
    company
  end

  def scoped_host_for(subdomain)
    ([subdomain] + Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app") + ["example", "com"]).join(".")
  end
end
