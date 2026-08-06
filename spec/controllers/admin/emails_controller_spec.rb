require "rails_helper"

RSpec.describe Admin::EmailsController, type: :request do
  let(:admin) { create(:user, :admin, active: true, email: "admin@example.com") }
  let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)

    host! scoped_host_for("admin")
  end

  describe "GET /email" do
    it "renderiza o formulário de teste de e-mail para admin" do
      sign_in admin

      get admin_email_path

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Teste de envio", "E-mail do destinatário")
      end
    end
  end

  describe "POST /email" do
    it "envia e-mail de teste para o destinatário informado" do
      sign_in admin
      allow(AdminMailer).to receive(:test_email).and_return(mail_delivery)

      post admin_email_path, params: { email_test: { email: "Destino@Example.com" } }

      aggregate_failures do
        expect(AdminMailer).to have_received(:test_email).with("destino@example.com", admin)
        expect(mail_delivery).to have_received(:deliver_later)
        expect(response).to redirect_to(admin_email_path)
        expect(flash[:notice]).to eq("E-mail de teste enviado para destino@example.com.")
      end
    end

    it "não envia quando o e-mail é inválido" do
      sign_in admin
      allow(AdminMailer).to receive(:test_email)

      post admin_email_path, params: { email_test: { email: "email-invalido" } }

      aggregate_failures do
        expect(AdminMailer).not_to have_received(:test_email)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Informe um e-mail válido.")
      end
    end

    it "redireciona usuário não admin para login" do
      gestor = create(:user, :gestor, active: true)
      sign_in gestor

      post admin_email_path, params: { email_test: { email: "destino@example.com" } }

      expect(response).to redirect_to(login_root_url(subdomain: "login"))
    end
  end

  def scoped_host_for(subdomain)
    tld_labels = ["example", "com"]
    extra_domain_labels = Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app")
    ([subdomain] + extra_domain_labels + tld_labels).join(".")
  end
end
