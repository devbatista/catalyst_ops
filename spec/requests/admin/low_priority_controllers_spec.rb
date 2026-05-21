require "rails_helper"

RSpec.describe "Controllers Admin de prioridade baixa", type: :request do
  let(:admin) { create(:user, :admin, active: true) }
  let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)

    host! scoped_host_for("admin")
    sign_in admin

    allow(UserMailer).to receive(:welcome_email).and_return(mail_delivery)
    allow(SupportTicketNotifications).to receive(:notify_message)
  end

  it "renderiza índices principais do admin autenticado" do
    plan = create(:plan, name: "Plano Admin")
    company = create(:company, plan: plan, name: "Empresa Admin")
    subscription = create(:subscription, company: company, subscription_plan: plan)
    client = create(:client, company: company)
    create(:order_service, company: company, client: client)
    create(:support_ticket, company: company, user: admin, subject: "Ticket Admin")
    create(:knowledge_base_article, title: "Artigo Admin")
    create(:subscription_reconciliation_event, subscription: subscription, company: company)

    [
      "/",
      "/companies",
      "/users",
      "/plans",
      "/subscriptions",
      "/tickets",
      "/order_services",
      "/knowledge_base_articles",
      "/subscription_reconciliation_events"
    ].each do |path|
      get path
      expect(response).to have_http_status(:ok), "esperava 200 em #{path}, veio #{response.status}"
    end
  end

  it "filtra listagens administrativas por parâmetros comuns" do
    plan = create(:plan, name: "Plano Filtrado")
    company = create(:company, plan: plan, name: "Empresa Filtrada", email: "filtrada@example.com")
    subscription = create(:subscription, company: company, subscription_plan: plan)
    ticket = create(:support_ticket, company: company, user: admin, subject: "Ticket Filtrado", status: :aberto)
    article = create(:knowledge_base_article, title: "Artigo Filtrado", category: "Operação", audience: "gestor")
    event = create(
      :subscription_reconciliation_event,
      subscription: subscription,
      company: company,
      gateway_identifier: "gateway-filtrado",
      source_job: "job_filtrado",
      divergent: true,
      resolved: false,
      result_status: "error"
    )

    get "/companies", params: { q: "Filtrada" }
    expect(response.body).to include(company.name)

    get "/users", params: { role: "admin" }
    expect(response.body).to include(admin.email)

    get "/tickets", params: { q: "Filtrado", status: "aberto" }
    expect(response.body).to include(ticket.subject)

    get "/knowledge_base_articles", params: { q: "Filtrado", category: "Operação", audience: "gestor" }
    expect(response.body).to include(article.title)

    get "/subscription_reconciliation_events", params: {
      q: "gateway-filtrado",
      source_job: "job_filtrado",
      divergent: "true",
      resolved: "false",
      result_status: "error"
    }
    expect(response.body).to include(event.gateway_identifier)
  end

  it "mostra evento de reconciliação e restringe acesso não admin" do
    event = create(:subscription_reconciliation_event, gateway_identifier: "gateway-show")

    get "/subscription_reconciliation_events/#{event.id}"
    expect(response.body).to include("gateway-show")

    sign_out admin
    gestor = create(:user, :gestor, company: event.company, active: true)
    sign_in gestor

    get "/subscription_reconciliation_events"
    expect(response).to redirect_to(login_root_url(subdomain: "login"))
  end

  it "cria mensagem de suporte pelo admin" do
    ticket = create(:support_ticket, user: admin)

    expect do
      post "/support_messages", params: {
        support_message: {
          support_ticket_id: ticket.id,
          body: "Mensagem enviada pelo admin"
        }
      }
    end.to change(SupportMessage, :count).by(1)

    aggregate_failures do
      expect(response).to redirect_to(admin_ticket_path(ticket))
      expect(SupportTicketNotifications).to have_received(:notify_message)
      expect(ticket.support_messages.exists?(body: "Mensagem enviada pelo admin")).to be(true)
    end
  end

  def scoped_host_for(subdomain)
    tld_labels = ["example", "com"]
    extra_domain_labels = Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app")
    ([subdomain] + extra_domain_labels + tld_labels).join(".")
  end
end
