require "rails_helper"

RSpec.describe "Cliente::BudgetApprovals", type: :request do
  let(:plan) { create(:plan) }
  let(:company) { create(:company, plan: plan) }
  let!(:subscription) { create(:subscription, company: company, subscription_plan: plan, status: :active) }
  let(:client) { create(:client, company: company, email: "cliente@example.com") }
  let(:budget) { create(:budget, company: company, client: client, status: :enviado, approval_sent_at: Time.current) }
  let(:token) { budget.approval_token(expires_in: 1.week) }
  let(:cliente_host) { scoped_host_for("cliente") }

  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)

    host! cliente_host
  end

  describe "GET /budget_approvals/:token" do
    it "mostra orçamento com token válido" do
      get budget_approval_url(token)

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(budget.title)
      end
    end

    it "retorna não encontrado com token inválido ou expirado" do
      get budget_approval_url("token-invalido")

      aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("Link inválido ou expirado.")
      end
    end
  end

  describe "PATCH /budget_approvals/:token/approve" do
    it "aprova orçamento e cria ordem de serviço" do
      allow(BudgetMailer).to receive_message_chain(:notify_manager_order_service_created, :deliver_later)

      expect do
        patch approve_budget_approval_url(token)
      end.to change(OrderService, :count).by(1)

      aggregate_failures do
        expect(response).to redirect_to(budget_approval_path(token: token, subdomain: "cliente"))
        expect(flash[:notice]).to eq("Orçamento aprovado com sucesso.")
        expect(budget.reload).to be_aprovado
        expect(budget.approved_at).to be_present
        expect(budget.order_service).to be_present
      end
    end

    it "não aprova novamente orçamento já aprovado" do
      budget.update!(status: :aprovado, approved_at: Time.current)

      expect do
        patch approve_budget_approval_url(token)
      end.not_to change(OrderService, :count)

      aggregate_failures do
        expect(response).to redirect_to(budget_approval_path(token: token, subdomain: "cliente"))
        expect(flash[:notice]).to eq("Este orçamento já foi aprovado.")
      end
    end
  end

  describe "PATCH /budget_approvals/:token/reject" do
    it "rejeita orçamento com motivo informado" do
      patch reject_budget_approval_url(token), params: { rejection_reason: "Valor acima do esperado" }

      aggregate_failures do
        expect(response).to redirect_to(budget_approval_path(token: token, subdomain: "cliente"))
        expect(flash[:notice]).to eq("Orçamento rejeitado com sucesso.")
        expect(budget.reload).to be_rejeitado
        expect(budget.rejection_reason).to eq("Valor acima do esperado")
      end
    end

    it "exige motivo para rejeição" do
      patch reject_budget_approval_url(token), params: { rejection_reason: "" }

      aggregate_failures do
        expect(response).to redirect_to(budget_approval_path(token: token, subdomain: "cliente"))
        expect(flash[:alert]).to include("não pode ficar em branco")
        expect(budget.reload).to be_enviado
      end
    end

    it "não rejeita novamente orçamento já rejeitado" do
      budget.update!(status: :rejeitado, rejected_at: Time.current, rejection_reason: "Sem verba")

      patch reject_budget_approval_url(token), params: { rejection_reason: "Outro motivo" }

      aggregate_failures do
        expect(response).to redirect_to(budget_approval_path(token: token, subdomain: "cliente"))
        expect(flash[:notice]).to eq("Este orçamento já foi rejeitado.")
        expect(budget.reload.rejection_reason).to eq("Sem verba")
      end
    end
  end

  def budget_approval_url(token)
    "http://#{cliente_host}/budget_approvals/#{token}"
  end

  def approve_budget_approval_url(token)
    "http://#{cliente_host}/budget_approvals/#{token}/approve"
  end

  def reject_budget_approval_url(token)
    "http://#{cliente_host}/budget_approvals/#{token}/reject"
  end

  def scoped_host_for(subdomain)
    tld_labels = ["example", "com"]
    extra_domain_labels = Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app")

    ([subdomain] + extra_domain_labels + tld_labels).join(".")
  end
end
