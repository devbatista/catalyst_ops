require "rails_helper"

RSpec.describe "Admin::MetricsController", type: :request do
  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)
    host! scoped_host_for("admin")
    sign_in admin
    allow(Audit::Log).to receive(:call)
  end

  let(:admin) { create(:user, :admin, active: true) }

  it "renderiza métricas com fallback sem Sentry" do
    get "/metrics", params: { period: "7d" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sentry")
    expect(response.body).to include("7d")
  end

  it "não dispara teste Sentry quando integração não está configurada" do
    post "/metrics/test_sentry", params: { period: "7d" }

    expect(response).to redirect_to(admin_metrics_path(period: "7d"))
  end

  def scoped_host_for(subdomain)
    ([subdomain] + Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app") + ["example", "com"]).join(".")
  end
end
