require "rails_helper"

RSpec.describe "Segurança de status em App::OrderServices", type: :request do
  let(:plan) { create(:plan) }
  let(:company) do
    create(
      :company,
      plan: plan,
      active: true,
      allow_order_service_without_budget: true,
      terms_version_accepted: TermsOfUse.current_version,
      terms_accepted_at: Time.current
    )
  end
  let!(:subscription) { create(:subscription, company: company, subscription_plan: plan, status: :active) }
  let(:user) { create(:user, :gestor, company: company, active: true) }
  let(:client) { create(:client, company: company) }
  let(:app_host) { scoped_host_for("app") }

  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)

    host! app_host
    sign_in user
  end

  it "ignora status enviado no PATCH update" do
    order_service = create(
      :order_service,
      company: company,
      client: client,
      status: :pendente,
      scheduled_at: nil,
      expected_end_at: nil
    )

    patch app_order_service_url(order_service), params: {
      order_service: {
        title: "OS atualizada",
        description: "Descrição válida da ordem de serviço",
        client_id: client.id,
        status: "finalizada"
      }
    }

    aggregate_failures do
      expect(response).to redirect_to(app_order_service_url(order_service))
      expect(order_service.reload).to be_pendente
      expect(order_service.title).to eq("OS atualizada")
    end
  end

  it "bloqueia transição inválida em update_status" do
    order_service = create(:order_service, company: company, client: client, status: :pendente, scheduled_at: nil, expected_end_at: nil)

    patch update_status_app_order_service_url(order_service), params: { status: "finalizada" }

    aggregate_failures do
      expect(response).to redirect_to(app_order_service_url(order_service))
      expect(flash[:alert]).to eq("Transição de status inválida.")
      expect(order_service.reload).to be_pendente
    end
  end

  it "permite acessar agendamento para ordem pendente" do
    order_service = create(:order_service, company: company, client: client, status: :pendente, scheduled_at: nil, expected_end_at: nil)

    get schedule_app_order_service_url(order_service)

    expect(response).to have_http_status(:ok)
  end

  it "bloqueia agendamento para estados não elegíveis" do
      order_service = create(
        :order_service,
        company: company,
        client: client,
        status: :finalizada,
        scheduled_at: 1.day.from_now,
        expected_end_at: 2.days.from_now
      )

    get schedule_app_order_service_url(order_service)

    aggregate_failures do
      expect(response).to redirect_to(app_order_service_url(order_service))
      expect(flash[:alert]).to eq("Só é possível agendar ordens pendentes ou atrasadas.")
    end
  end

  def app_order_service_url(order_service)
    "http://#{app_host}/order_services/#{order_service.id}"
  end

  def update_status_app_order_service_url(order_service)
    "http://#{app_host}/order_services/#{order_service.id}/update_status"
  end

  def schedule_app_order_service_url(order_service)
    "http://#{app_host}/order_services/#{order_service.id}/schedule"
  end

  def scoped_host_for(subdomain)
    tld_labels = ["example", "com"]
    extra_domain_labels = Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app")

    ([subdomain] + extra_domain_labels + tld_labels).join(".")
  end
end
