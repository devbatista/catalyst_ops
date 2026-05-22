require "rails_helper"

RSpec.describe "Admin::LogsController", type: :request do
  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    host! scoped_host_for("admin")
    sign_in admin
  end

  let(:admin) { create(:user, :admin, active: true) }

  it "lista e filtra logs" do
    company = create(:company, name: "Empresa Logs")
    event = create(:audit_event, company: company, action: "job.failed", source: "job", request_id: "req-filtrado", occurred_at: Time.zone.local(2026, 5, 10, 12, 0, 0))
    create(:audit_event, action: "plan.created", source: "system")

    get "/logs", params: {
      action_name: "job.failed",
      source: "job",
      company_id: company.id,
      date_from: "2026-05-10",
      date_to: "2026-05-10"
    }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(event.action)
    expect(response.body).to include(company.name)
  end

  it "mostra log e exporta CSV" do
    event = create(:audit_event, action: "job.failed", request_id: "req-csv")

    get "/logs/#{event.id}"
    expect(response.body).to include("req-csv")

    get "/logs.csv", params: { action_name: "job.failed" }
    expect(response.media_type).to eq("text/csv")
    expect(response.body).to include("req-csv")
  end

  def scoped_host_for(subdomain)
    ([subdomain] + Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app") + ["example", "com"]).join(".")
  end
end
