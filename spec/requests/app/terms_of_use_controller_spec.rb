require "rails_helper"

RSpec.describe "App::TermsOfUseController", type: :request do
  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)
    host! scoped_host_for("app")
    sign_in user
    allow(Audit::Log).to receive(:call)
  end

  let(:plan) { create(:plan) }
  let(:company) { create(:company, plan: plan, active: true, terms_version_accepted: nil, terms_accepted_at: nil) }
  let!(:subscription) { create(:subscription, company: company, subscription_plan: plan, status: :active) }
  let(:user) { create(:user, :gestor, company: company, active: true) }

  it "exibe termos pendentes" do
    get "/terms_of_use"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(TermsOfUse.title)
  end

  it "aceita termos atuais com metadados de requisição" do
    patch "/terms_of_use", params: { accept_terms: "1" }, headers: { "HTTP_USER_AGENT" => "RSpec UA" }

    expect(response).to redirect_to(app_dashboard_path)
    expect(company.reload.terms_version_accepted).to eq(TermsOfUse.current_version)
    expect(company.terms_accepted_by_user).to eq(user)
    expect(company.terms_accepted_user_agent).to eq("RSpec UA")
    expect(Audit::Log).to have_received(:call).with(hash_including(action: "terms.accepted", actor: user, company: company))
  end

  it "não aceita sem checkbox" do
    patch "/terms_of_use", params: { accept_terms: "0" }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(company.reload.terms_accepted_at).to be_nil
  end

  def scoped_host_for(subdomain)
    ([subdomain] + Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app") + ["example", "com"]).join(".")
  end
end
