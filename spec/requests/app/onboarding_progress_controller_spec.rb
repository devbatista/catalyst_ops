require "rails_helper"

RSpec.describe "App::OnboardingProgressController", type: :request do
  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    host! scoped_host_for("app")
    sign_in user
  end

  let(:company) { active_company }
  let(:user) { create(:user, :gestor, company: company, active: true) }

  it "exibe progresso atual em JSON" do
    get "/onboarding_progress", as: :json

    expect(response).to have_http_status(:ok), response.body
    payload = parsed_json_response
    expect(payload.dig("onboarding_progress", "steps_total")).to eq(UserOnboardingProgress::STEP_KEYS.size)
  end

  it "marca etapa concluída" do
    patch "/onboarding_progress", params: { operation: "complete_step", step_key: "created_budget" }, as: :json

    expect(response).to have_http_status(:ok), response.body
    payload = parsed_json_response
    expect(payload.dig("onboarding_progress", "completed_steps")).to include("created_budget" => true)
    expect(user.user_onboarding_progress.reload).to be_completed_step("created_budget")
  end

  it "retorna erro para operação inválida" do
    patch "/onboarding_progress", params: { operation: "invalida" }, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(parsed_json_response["success"]).to be false
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

  def parsed_json_response
    expect(response.media_type).to eq("application/json"), response.body.first(1_000)

    JSON.parse(response.body)
  end
end
