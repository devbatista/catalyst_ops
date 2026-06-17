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

  it "renderiza edição quando atualização tem dados inválidos" do
    order_service = create(:order_service, company: company, client: client, status: :agendada)

    patch app_order_service_url(order_service), params: {
      order_service: {
        title: "",
        description: "Descrição válida da ordem de serviço",
        client_id: client.id
      }
    }

    aggregate_failures do
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).not_to be_redirect
      expect(flash[:alert]).to include("Title")
      expect(order_service.reload.title).not_to eq("")
    end
  end

  it "cria OS direta quando a empresa permite criar sem orçamento" do
    technician = create(:user, :tecnico, company: company, active: true)

    expect do
      post "http://#{app_host}/order_services", params: {
        order_service: {
          title: "OS direta válida",
          description: "Descrição válida da ordem direta",
          client_id: client.id,
          scheduled_at: 1.day.from_now,
          expected_end_at: 1.day.from_now + 2.hours,
          user_ids: [technician.id],
          service_items_attributes: {
            "0" => {
              description: "Serviço inicial",
              quantity: 1,
              unit_price: 100
            }
          }
        }
      }
    end.to change(OrderService, :count).by(1)

    aggregate_failures do
      created = OrderService.last
      expect(response).to redirect_to(app_order_service_url(created))
      expect(created).to be_created_without_budget
      expect(created).to be_agendada
      expect(created.users).to include(technician)
    end
  end

  it "bloqueia criação direta de OS quando a empresa exige orçamento" do
    company.update!(allow_order_service_without_budget: false)

    post "http://#{app_host}/order_services", params: {
      order_service: {
        title: "OS bloqueada",
        description: "Descrição válida da ordem bloqueada",
        client_id: client.id
      }
    }

    aggregate_failures do
      expect(response).to redirect_to("http://#{app_host}/budgets/new?client_id=#{client.id}")
      expect(flash[:alert]).to eq("Sua empresa não permite criar OS sem orçamento. Crie um orçamento primeiro.")
    end
  end

  it "bloqueia criação de OS quando o limite do plano foi atingido" do
    allow_any_instance_of(Company).to receive(:can_create_order?).and_return(false)

    post "http://#{app_host}/order_services", params: {
      order_service: {
        title: "OS acima do limite",
        description: "Descrição válida da ordem bloqueada",
        client_id: client.id
      }
    }

    aggregate_failures do
      expect(response).to redirect_to("http://#{app_host}/order_services")
      expect(flash[:alert]).to eq("Limite de ordens de serviço atingido para o seu plano atual.")
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

  it "redireciona para a agenda ao atualizar status para agendada" do
    order_service = create(:order_service, company: company, client: client, status: :pendente, scheduled_at: nil, expected_end_at: nil)

    patch update_status_app_order_service_url(order_service), params: { status: "agendada" }

    expect(response).to redirect_to(schedule_app_order_service_url(order_service))
  end

  it "permite transição válida de status e marca onboarding" do
    technician = create(:user, :tecnico, company: company, active: true)
    order_service = create(:order_service, company: company, client: client, status: :agendada)
    create(:assignment, order_service: order_service, user: technician)
    allow_any_instance_of(App::OrderServicesController).to receive(:mark_onboarding_step)

    patch update_status_app_order_service_url(order_service), params: { status: "em_andamento" }

    aggregate_failures do
      expect(response).to redirect_to(app_order_service_url(order_service))
      expect(flash[:notice]).to eq("Status atualizado com sucesso.")
      expect(order_service.reload).to be_em_andamento
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

  it "agenda OS pendente com técnico e datas válidas" do
    technician = create(:user, :tecnico, company: company, active: true)
    order_service = create(:order_service, company: company, client: client, status: :pendente, scheduled_at: nil, expected_end_at: nil)
    scheduled_at = 2.days.from_now.change(usec: 0)
    expected_end_at = scheduled_at + 2.hours

    patch "http://#{app_host}/order_services/#{order_service.id}/perform_schedule", params: {
      order_service: {
        scheduled_at: scheduled_at.strftime("%Y-%m-%dT%H:%M"),
        expected_end_at: expected_end_at.strftime("%Y-%m-%dT%H:%M"),
        user_ids: [technician.id]
      }
    }

    aggregate_failures do
      expect(response).to redirect_to(app_order_service_url(order_service))
      expect(flash[:notice]).to eq("Ordem de Serviço agendada com sucesso.")
      expect(order_service.reload).to be_agendada
      expect(order_service.users).to include(technician)
    end
  end

  it "renderiza agenda quando dados de agendamento são inválidos" do
    order_service = create(:order_service, company: company, client: client, status: :pendente, scheduled_at: nil, expected_end_at: nil)

    patch "http://#{app_host}/order_services/#{order_service.id}/perform_schedule", params: {
      order_service: {
        scheduled_at: "",
        expected_end_at: "",
        user_ids: [""]
      }
    }

    aggregate_failures do
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).not_to be_redirect
      expect(flash[:alert]).to include("Scheduled at")
      expect(order_service.reload).to be_pendente
    end
  end

  it "lista ordens sem técnico e atrasadas da empresa" do
    unassigned_order = create(:order_service, company: company, client: client, title: "OS Sem Técnico", status: :pendente)
    overdue_order = create(:order_service, company: company, client: client, title: "OS Atrasada", status: :atrasada, scheduled_at: 3.days.ago, expected_end_at: 2.days.ago)
    assigned_order = create(:order_service, company: company, client: client, title: "OS Com Técnico", status: :agendada)
    create(:assignment, order_service: assigned_order, user: create(:user, :tecnico, company: company, active: true))

    get "/order_services/unassigned"
    expect(response.body).to include(unassigned_order.id)
    expect(response.body).not_to include(assigned_order.id)

    get "/order_services/overdue"
    expect(response.body).to include(overdue_order.id)
  end

  it "envia PDF para o cliente quando OS está concluída" do
    delivery = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
    order_service = create(:order_service, company: company, client: client, status: :concluida)
    allow(OrderServiceMailer).to receive(:send_pdf_to_client).and_return(delivery)

    post "/order_services/#{order_service.id}/send_pdf_to_client"

    aggregate_failures do
      expect(response).to redirect_to(app_order_service_url(order_service))
      expect(flash[:notice]).to eq("PDF enviado para o cliente com sucesso.")
      expect(OrderServiceMailer).to have_received(:send_pdf_to_client).with(order_service, user)
      expect(delivery).to have_received(:deliver_later)
    end
  end

  it "bloqueia envio de PDF quando cliente não tem e-mail" do
    client_without_email = create(:client, company: company)
    client_without_email.update_column(:email, "")
    order_service = create(:order_service, company: company, client: client_without_email, status: :concluida)

    post "/order_services/#{order_service.id}/send_pdf_to_client"

    aggregate_failures do
      expect(response).to redirect_to(app_order_service_url(order_service))
      expect(flash[:alert]).to eq("O cliente não possui e-mail cadastrado.")
    end
  end

  it "bloqueia envio de PDF quando usuário não é gestor" do
    admin = create(:user, :admin, company: company, active: true)
    order_service = create(:order_service, company: company, client: client, status: :concluida)
    sign_out user
    sign_in admin

    post "/order_services/#{order_service.id}/send_pdf_to_client"

    aggregate_failures do
      expect(response).to redirect_to(app_order_service_url(order_service))
      expect(flash[:alert]).to eq("Somente gestores podem enviar o PDF da OS para o cliente.")
    end
  end

  it "bloqueia envio de PDF quando OS não está concluída ou finalizada" do
    order_service = create(:order_service, company: company, client: client, status: :agendada)

    post "/order_services/#{order_service.id}/send_pdf_to_client"

    aggregate_failures do
      expect(response).to redirect_to(app_order_service_url(order_service))
      expect(flash[:alert]).to eq("O envio do PDF está disponível apenas para OS concluída ou finalizada.")
    end
  end

  it "atualiza dados do comprovante de recebimento" do
    order_service = create(:order_service, company: company, client: client, status: :concluida)

    patch "/order_services/#{order_service.id}/update_receipt_data", params: {
      order_service: {
        received_items_attributes: {
          "0" => {
            name: "Notebook",
            brand: "Dell",
            model: "Latitude",
            serial_number: "ABC123",
            quantity: 1,
            condition_notes: "Bom estado",
            reported_issue: "Não liga",
            accessories: "Fonte"
          }
        }
      }
    }

    aggregate_failures do
      expect(response).to redirect_to("http://#{app_host}/order_services/#{order_service.id}/receipt")
      expect(flash[:notice]).to eq("Dados do comprovante de recebimento atualizados.")
      expect(order_service.received_items.reload.first.name).to eq("Notebook")
    end
  end

  it "bloqueia comprovante de devolução para status não elegível" do
    order_service = create(:order_service, company: company, client: client, status: :agendada)

    get "/order_services/#{order_service.id}/return_receipt"

    aggregate_failures do
      expect(response).to redirect_to(app_order_service_url(order_service))
      expect(flash[:alert]).to eq("A devolução está disponível apenas para OS concluída, finalizada ou cancelada.")
    end
  end

  it "bloqueia geração de comprovante de devolução sem itens recebidos" do
    order_service = create(:order_service, company: company, client: client, status: :concluida)

    get "/order_services/#{order_service.id}/generate_return_receipt_pdf"

    aggregate_failures do
      expect(response).to redirect_to(app_order_service_url(order_service))
      expect(flash[:alert]).to eq("Cadastre ao menos um item recebido para gerar o comprovante de devolução.")
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
