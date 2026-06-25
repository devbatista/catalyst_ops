require "rails_helper"

RSpec.describe "Controllers App de prioridade baixa", type: :request do
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
  let(:user) { create(:user, :gestor, company: company, active: true) }
  let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)

    host! scoped_host_for("app")
    create(:subscription, company: company, subscription_plan: plan, status: :active)
    sign_in user

    allow(UserMailer).to receive(:welcome_email).and_return(mail_delivery)
    allow(SupportTicketNotifications).to receive(:notify_message)
  end

  it "renderiza índices principais do app autenticado" do
    create(:client, company: company, name: "Cliente App")
    create(:user, :tecnico, company: company, active: true, name: "Técnico App")
    create(:knowledge_base_article, title: "Artigo App", audience: "gestor")

    [
      "/",
      "/order_services",
      "/clients",
      "/technicians",
      "/support",
      "/knowledge_base",
      "/financial",
      "/calendar",
      "/reports",
      "/configurations"
    ].each do |path|
      get path
      expect(response).to have_http_status(:ok), "esperava 200 em #{path}, veio #{response.status}"
    end
  end

  it "filtra clientes, técnicos e ordens nos índices" do
    client = create(:client, company: company, name: "Cliente Filtrado")
    technician = create(:user, :tecnico, company: company, active: true, name: "Técnico Filtrado")
    order_service = create(:order_service, company: company, client: client, title: "OS Filtrada", status: :agendada)

    get "/clients", params: { q: "Filtrado" }
    expect(response.body).to include(client.name)

    get "/technicians", params: { q: "Filtrado" }
    expect(response.body).to include(technician.name)

    get "/order_services", params: { status: "agendada", code: order_service.code }
    expect(response.body).to include(order_service.code.to_s)
    expect(response.body).to include(client.name)
  end

  it "retorna técnicos e eventos do calendário em JSON" do
    client = create(:client, company: company)
    technician = create(:user, :tecnico, company: company, active: true, name: "Agenda Técnica")
    order_service = create(:order_service, company: company, client: client, title: "OS Agenda", status: :agendada)
    create(:assignment, order_service: order_service, user: technician)

    get "/calendar/technicians", as: :json
    technician_names = JSON.parse(response.body).pluck("name")
    expect(technician_names).to include("Agenda Técnica")

    get "/calendar/events", params: { technician_ids: technician.id }, as: :json
    event_titles = JSON.parse(response.body).pluck("base_title")
    expect(event_titles).to include("OS Agenda")
  end

  it "cria mensagem de suporte pelo app" do
    ticket = create(:support_ticket, company: company, user: user)

    expect do
      post "/support_messages", params: {
        support_message: {
          support_ticket_id: ticket.id,
          body: "Mensagem enviada pelo app"
        }
      }
    end.to change(SupportMessage, :count).by(1)

    aggregate_failures do
      expect(response).to redirect_to(app_support_ticket_path(ticket))
      expect(SupportTicketNotifications).to have_received(:notify_message)
      expect(ticket.support_messages.exists?(body: "Mensagem enviada pelo app")).to be(true)
    end
  end

  it "mostra gestor como técnico operacional no plano Starter" do
    plan.update!(free: true, transaction_amount: 0, max_technicians: 1)
    user.update!(can_be_technician: true)

    get "/technicians"

    expect(response.body).to include(user.name)
  end

  it "mostra Suporte como dropdown restrito à base de conhecimento no menu do plano Starter" do
    plan.update!(free: true, transaction_amount: 0, support_level: "Base de conhecimento")

    get "/knowledge_base"

    aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("onboarding-tour-support-menu")
      expect(response.body).to include("has-arrow")
      expect(response.body).to include(%(href="/knowledge_base"))
      expect(response.body).to include("Base de conhecimento")
      expect(response.body).not_to include("Visão geral")
      expect(response.body).not_to include("Tickets")
      expect(response.body).not_to include("Sugestões")
      expect(response.body).not_to include("Contato rápido")
      expect(response.body).not_to include("Ver tour novamente")
    end
  end

  it "mostra Suporte como dropdown com subitens completos no menu do plano Profissional" do
    plan.update!(name: "Profissional", free: false, transaction_amount: 199, support_level: "prioritário")

    get "/support"

    aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("onboarding-tour-support-menu")
      expect(response.body).to include("has-arrow")
      expect(response.body).to include(%(href="/support"))
      expect(response.body).to include(%(href="/support?section=tickets"))
      expect(response.body).to include(%(href="/support?section=knowledge_base"))
      expect(response.body).to include(%(href="/support?section=suggestions"))
      expect(response.body).to include(%(href="/support?section=quick_contact"))
      expect(response.body).to include("Central de suporte")
      expect(response.body).to include("Abrir novo ticket")
      expect(response.body).to include("Visão geral")
      expect(response.body).to include("Tickets")
      expect(response.body).to include("Sugestões")
      expect(response.body).to include("Contato rápido")
    end
  end

  it "não mostra cancelamento de assinatura nas configurações do plano Starter" do
    plan.update!(free: true, transaction_amount: 0, max_technicians: 1)

    get "/configurations"

    aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Assinatura")
      expect(response.body).not_to include("Cancelamento")
      expect(response.body).not_to include("Cancelar assinatura no fim do período")
    end
  end

  def scoped_host_for(subdomain)
    tld_labels = ["example", "com"]
    extra_domain_labels = Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app")
    ([subdomain] + extra_domain_labels + tld_labels).join(".")
  end
end
