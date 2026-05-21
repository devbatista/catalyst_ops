require "rails_helper"

RSpec.describe "App::SupportTickets", type: :request do
  let(:plan) { create(:plan) }
  let(:company) do
    create(
      :company,
      plan: plan,
      active: true,
      terms_version_accepted: TermsOfUse.current_version,
      terms_accepted_at: Time.current
    )
  end
  let(:user) { create(:user, :gestor, company: company, active: true) }

  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)

    host! scoped_host_for("app")
    create(:subscription, company: company, status: :active)
    sign_in user

    allow(SupportTicketNotifications).to receive(:notify_created)
    allow(SupportTicketNotifications).to receive(:notify_status_changed)
  end

  describe "GET /support?section=tickets" do
    it "lista tickets filtrando por status e categoria" do
      expected_ticket = create(
        :support_ticket,
        company: company,
        status: :em_andamento,
        category: :problema_tecnico,
        subject: "Erro no orçamento"
      )
      create(:support_ticket, company: company, status: :aberto, category: :problema_tecnico, subject: "Ticket aberto")
      create(:support_ticket, company: company, status: :em_andamento, category: :financeiro, subject: "Ticket financeiro")
      create(:support_ticket, status: :em_andamento, category: :problema_tecnico, subject: "Outra empresa")

      get app_support_index_path, params: { section: "tickets", status: "em_andamento", category: "problema_tecnico" }

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(expected_ticket.subject)
        expect(response.body).not_to include("Ticket aberto")
        expect(response.body).not_to include("Ticket financeiro")
        expect(response.body).not_to include("Outra empresa")
      end
    end

    it "pagina os tickets conforme parâmetro per" do
      visible_ticket = create(:support_ticket, company: company, subject: "Ticket visível")
      hidden_ticket = create(:support_ticket, company: company, subject: "Ticket fora da primeira página")

      visible_ticket.update_columns(last_reply_at: 1.hour.ago, created_at: 1.hour.ago)
      hidden_ticket.update_columns(last_reply_at: 2.days.ago, created_at: 2.days.ago)

      get app_support_index_path, params: { section: "tickets", per: 1, page: 1 }

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Ticket visível")
        expect(response.body).not_to include("Ticket fora da primeira página")
      end
    end
  end

  describe "GET /support_tickets/:id" do
    it "mostra ticket da empresa do usuário" do
      ticket = create(:support_ticket, company: company, subject: "Meu ticket", description: "Detalhes do ticket")
      create(:support_message, support_ticket: ticket, body: "Mensagem do histórico")

      get app_support_ticket_path(ticket)

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Meu ticket")
        expect(response.body).to include("Detalhes do ticket")
        expect(response.body).to include("Mensagem do histórico")
      end
    end

    it "retorna não encontrado para ticket de outra empresa" do
      other_ticket = create(:support_ticket, subject: "Ticket privado")

      get app_support_ticket_path(other_ticket)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /support_tickets/new" do
    it "renderiza o formulário com os padrões de novo ticket" do
      get new_app_support_ticket_path

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Novo ticket de suporte")
        expect(response.body).to include("selected=\"selected\" value=\"medio\"")
        expect(response.body).to include("selected=\"selected\" value=\"normal\"")
      end
    end
  end

  describe "POST /support_tickets" do
    it "cria ticket com sucesso" do
      expect do
        post app_support_tickets_path, params: {
          support_ticket: {
            subject: "Não consigo gerar PDF",
            description: "O botão retorna erro.",
            category: "problema_tecnico",
            impact: "alto",
            priority: "alta"
          }
        }
      end.to change(SupportTicket, :count).by(1)

      ticket = SupportTicket.order(:created_at).last

      aggregate_failures do
        expect(response).to redirect_to(app_support_ticket_path(ticket))
        expect(flash[:notice]).to eq("Ticket criado com sucesso.")
        expect(ticket.company).to eq(company)
        expect(ticket.user).to eq(user)
        expect(ticket).to be_aberto
        expect(SupportTicketNotifications).to have_received(:notify_created).with(ticket: ticket, actor: user)
      end
    end

    it "renderiza erro quando dados são inválidos" do
      expect do
        post app_support_tickets_path, params: {
          support_ticket: {
            subject: "",
            description: "",
            category: "problema_tecnico",
            impact: "alto",
            priority: "alta"
          }
        }
      end.not_to change(SupportTicket, :count)

      aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Novo ticket de suporte")
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "PATCH /support_tickets/:id/close" do
    it "fecha ticket e retorna JSON de sucesso" do
      ticket = create(:support_ticket, company: company, status: :em_andamento)

      patch close_app_support_ticket_path(ticket), as: :json

      json = JSON.parse(response.body)

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(json).to include(
          "success" => true,
          "status" => "fechado",
          "message" => "Ticket fechado com sucesso."
        )
        expect(ticket.reload).to be_fechado
        expect(SupportTicketNotifications).to have_received(:notify_status_changed).with(
          ticket: ticket,
          actor: user,
          previous_status: "em_andamento"
        )
      end
    end

    it "retorna erro JSON quando não consegue fechar o ticket" do
      ticket = create(:support_ticket, company: company, status: :cancelado)

      patch close_app_support_ticket_path(ticket), as: :json

      json = JSON.parse(response.body)

      aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json["success"]).to be(false)
        expect(json["errors"]).to include("Status Não pode ser alterado em tickets fechado ou cancelado")
      end
    end
  end

  def scoped_host_for(subdomain)
    tld_labels = ["example", "com"]
    extra_domain_labels = Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app")
    ([subdomain] + extra_domain_labels + tld_labels).join(".")
  end
end
