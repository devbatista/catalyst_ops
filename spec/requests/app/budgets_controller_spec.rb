require "rails_helper"

RSpec.describe "App::BudgetsController", type: :request do
  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)
    host! scoped_host_for("app")
    sign_in user
    allow(BudgetMailer).to receive_message_chain(:approval_request_to_client, :deliver_later)
  end

  let(:plan) { create(:plan, max_budgets: 10, max_orders: 10) }
  let(:company) { create(:company, plan: plan, active: true, terms_version_accepted: TermsOfUse.current_version, terms_accepted_at: Time.current) }
  let!(:subscription) { create(:subscription, company: company, subscription_plan: plan, status: :active) }
  let(:user) { create(:user, :gestor, company: company, active: true) }
  let(:client) { create(:client, company: company, name: "Cliente Budget") }

  it "lista, filtra e mostra orçamento da empresa" do
    budget = create(:budget, company: company, client: client, title: "Orçamento Filtrado")
    other_company = active_company
    create(:budget, company: other_company, client: create(:client, company: other_company), title: "Outro orçamento")

    get "/budgets", params: { q: "Filtrado", client_id: client.id }
    expect(response.body).to include("Orçamento Filtrado")
    expect(response.body).not_to include("Outro orçamento")

    get "/budgets/#{budget.id}"
    expect(response.body).to include("Orçamento Filtrado")
  end

  it "cria e atualiza orçamento" do
    get "/budgets/new"
    expect(response).to have_http_status(:ok)

    post "/budgets", params: { budget: budget_params(title: "Novo orçamento") }
    budget = Budget.find_by!(title: "Novo orçamento")
    expect(response).to redirect_to(app_budgets_path)

    get "/budgets/#{budget.id}/edit"
    expect(response).to have_http_status(:ok)

    patch "/budgets/#{budget.id}", params: { budget: budget_params(title: "Orçamento atualizado") }
    expect(response).to redirect_to(app_budgets_path)
    expect(budget.reload.title).to eq("Orçamento atualizado")
  end

  it "envia para aprovação, rejeita e aprova criando OS" do
    budget = create(:budget, company: company, client: client)

    post "/budgets/#{budget.id}/send_for_approval"
    expect(response).to redirect_to(app_budget_path(budget))
    expect(budget.reload).to be_enviado

    patch "/budgets/#{budget.id}/reject", params: { rejection_reason: "Ajustar prazo" }
    expect(response).to redirect_to(app_budget_path(budget))
    expect(budget.reload).to be_rejeitado

    patch "/budgets/#{budget.id}", params: { budget: budget_params(title: "Revisado") }
    patch "/budgets/#{budget.id}/approve"

    expect(response).to redirect_to(app_budget_path(budget))
    expect(budget.reload).to be_aprovado
    expect(budget.order_service).to be_present
  end

  def budget_params(title:)
    {
      title: title,
      description: "Descrição do orçamento",
      client_id: client.id,
      estimated_delivery_days: 3,
      service_items_attributes: {
        "0" => { description: "Serviço", quantity: 1, unit_price: 100 }
      }
    }
  end

  def scoped_host_for(subdomain)
    ([subdomain] + Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app") + ["example", "com"]).join(".")
  end

  def active_company
    other_plan = create(:plan, max_budgets: 10, max_orders: 10)
    other_company = create(:company, plan: other_plan, active: true, terms_version_accepted: TermsOfUse.current_version, terms_accepted_at: Time.current)
    create(:subscription, company: other_company, subscription_plan: other_plan, status: :active)
    other_company
  end
end
