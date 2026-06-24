require "rails_helper"

RSpec.describe "Register::SignupsController", type: :request do
  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)
    host! scoped_host_for("register")
    allow(Audit::Log).to receive(:call)
  end

  let!(:plan) { create(:plan, status: "active", transaction_amount: 100) }

  it "exibe formulário de cadastro" do
    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(plan.name)
    expect(response.body).to include('type="text" name="signup[company][website]"')
  end

  it "exibe plano Starter gratuito como Grátis" do
    starter = create(:plan, :starter, status: "active")

    get "/"

    aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(starter.name)
      expect(response.body).to include("Grátis")
    end
  end

  it "pré-seleciona o plano Starter quando informado pelo site" do
    starter = create(:plan, :starter, status: "active")

    get "/", params: { plan: "starter" }

    aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/id="plan_#{starter.id}"[^>]*checked="checked"/)
    end
  end

  it "cria empresa, usuário e assinatura para pagamento pix" do
    expect do
      post "/signups", params: signup_params(payment_method: "pix")
    end.to change(Company, :count).by(1)
      .and change(User, :count).by(1)
      .and change(Subscription, :count).by(1)

    company = Company.order(:created_at).last
    expect(response).to redirect_to(success_path(company_id: company.id))
    expect(company.payment_method).to eq("pix")
    expect(company).to be_accepted_current_terms
    expect(Audit::Log).to have_received(:call).with(hash_including(action: "terms.accepted", company: company))
  end

  it "envia email de acesso sem redefinir senha para cadastro pago com cartão" do
    allow(Cmd::MercadoPago::CreateCreditCardPayment).to receive(:new)
      .and_return(instance_double("Result", call: Register::SignupsController::Result.new(true, nil)))
    expect_any_instance_of(User).to receive(:send_signup_welcome_email!)

    post "/signups", params: signup_params(payment_method: "credit_card").deep_merge(
      signup: { card_token: "card-token" }
    )

    company = Company.order(:created_at).last
    expect(response).to redirect_to(success_path(company_id: company.id))
  end

  it "cria empresa, gestor técnico e assinatura ativa para plano Starter gratuito sem iniciar pagamento" do
    starter = create(:plan, :starter)
    allow(CreateUser::PixPaymentJob).to receive(:perform_later)
    allow(CreateUser::BoletoPaymentJob).to receive(:perform_later)
    allow(Cmd::MercadoPago::CreateCreditCardPayment).to receive(:new)
    expect_any_instance_of(User).to receive(:send_starter_welcome_email!)

    expect do
      post "/signups", params: signup_params(
        plan_id: starter.id,
        payment_method: "credit_card",
        website: "www.beneditoejuanpublicidadeepropagandame.com.br"
      )
    end.to change(Company, :count).by(1)
      .and change(User, :count).by(1)
      .and change(Subscription, :count).by(1)

    company = Company.order(:created_at).last
    user = company.responsible
    subscription = company.current_subscription

    aggregate_failures do
      expect(response).to redirect_to(success_path(company_id: company.id, starter: "1"))
      expect(company.plan).to eq(starter)
      expect(user).to be_gestor
      expect(user).to be_can_be_technician
      expect(subscription).to be_active
      expect(subscription.end_date).to be_nil
      expect(subscription.transaction_amount).to eq(0)
      expect(company.website).to eq("https://www.beneditoejuanpublicidadeepropagandame.com.br")
      expect(CreateUser::PixPaymentJob).not_to have_received(:perform_later)
      expect(CreateUser::BoletoPaymentJob).not_to have_received(:perform_later)
      expect(Cmd::MercadoPago::CreateCreditCardPayment).not_to have_received(:new)
    end
  end

  it "renderiza erro quando termos não são aceitos" do
    post "/signups", params: signup_params(accept_terms: "0")

    expect(response).to have_http_status(:unprocessable_entity)
    expect(Company.find_by(email: "empresa-baixa@example.com")).to be_nil
  end

  it "renderiza erro para cupom inválido" do
    post "/signups", params: signup_params(coupon_code: "INVALIDO")

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Cupom inválido")
  end

  it "exibe tela de sucesso para empresa existente" do
    company = create(:company)

    get "/success", params: { company_id: company.id }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Foi enviado")
  end

  def signup_params(payment_method: "pix", accept_terms: "1", coupon_code: "", plan_id: plan.id, website: nil)
    {
      signup: {
        plan_id: plan_id,
        payment_method: payment_method,
        accept_terms: accept_terms,
        coupon_code: coupon_code,
        company: {
          name: "Empresa Baixa",
          document: CNPJ.generate,
          email: "empresa-baixa@example.com",
          phone: "(11) 99999-9999",
          zip_code: "01001-000",
          street: "Rua Teste",
          number: "123",
          neighborhood: "Centro",
          city: "São Paulo",
          state: "SP",
          website: website
        },
        user: {
          name: "Gestor Baixa",
          email: "gestor-baixa@example.com",
          password: "Password@123",
          password_confirmation: "Password@123"
        }
      }
    }
  end

  def scoped_host_for(subdomain)
    ([subdomain] + Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app") + ["example", "com"]).join(".")
  end
end
