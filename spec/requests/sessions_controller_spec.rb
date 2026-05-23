require "rails_helper"

RSpec.describe "SessionsController", type: :request do
  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    host! scoped_host_for("login")
    allow(Audit::AuthLogger).to receive(:login_succeeded)
    allow(Audit::AuthLogger).to receive(:login_failed)
    allow(Audit::AuthLogger).to receive(:logout_succeeded)
  end

  describe "POST /login" do
    it "autentica admin e redireciona para subdomínio admin" do
      admin = create(:user, :admin, active: true, password: "Password@123")

      post "/login", params: { email: admin.email.upcase, password: "Password@123" }

      expect(response).to redirect_to(admin_dashboard_url(subdomain: "admin"))
      expect(Audit::AuthLogger).to have_received(:login_succeeded).with(user: admin)
    end

    it "autentica gestor e redireciona para app" do
      company = active_company
      user = create(:user, :gestor, company: company, active: true, password: "Password@123")

      post "/login", params: { email: user.email, password: "Password@123" }

      expect(response).to redirect_to(app_dashboard_url(subdomain: "app"))
    end

    it "rejeita credenciais inválidas" do
      post "/login", params: { email: "x@example.com", password: "errada" }

      expect(response).to redirect_to(login_root_url(subdomain: "login"))
      expect(Audit::AuthLogger).to have_received(:login_failed).with(email: "x@example.com", user: nil)
    end

    it "recusa usuário inativo mesmo com senha correta" do
      user = create(:user, :gestor, active: false, password: "Password@123")

      post "/login", params: { email: user.email, password: "Password@123" }

      expect(response).to redirect_to(login_root_url(subdomain: "login"))
      expect(Audit::AuthLogger).to have_received(:login_failed).with(email: user.email, user: user)
      expect(Audit::AuthLogger).not_to have_received(:login_succeeded)
    end

    it "recusa usuário ativo com senha incorreta" do
      user = create(:user, :gestor, active: true, password: "Password@123")

      post "/login", params: { email: user.email, password: "Errada@123" }

      expect(response).to redirect_to(login_root_url(subdomain: "login"))
      expect(Audit::AuthLogger).to have_received(:login_failed).with(email: user.email, user: user)
    end
  end

  describe "GET /" do
    it "renderiza a tela de login para visitantes" do
      get "/"

      expect(response).to have_http_status(:ok)
    end

    it "redireciona admin já autenticado para o subdomínio admin" do
      admin = create(:user, :admin, active: true)
      sign_in admin

      get "/"

      expect(response).to redirect_to(admin_dashboard_url(subdomain: "admin"))
    end

    it "redireciona usuário comum autenticado para o subdomínio app" do
      company = active_company
      user = create(:user, :gestor, company: company, active: true)
      sign_in user

      get "/"

      expect(response).to redirect_to(app_dashboard_url(subdomain: "app"))
    end
  end

  describe "GET /forgot_password" do
    it "renderiza a tela de recuperação de senha" do
      get "/forgot_password"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /forgot_password" do
    it "dispara envio do e-mail quando o usuário existe" do
      user = create(:user, :gestor, active: true)
      allow_any_instance_of(User).to receive(:send_password_reset_email!)

      post "/forgot_password", params: { email: user.email.upcase }

      expect(response).to redirect_to(login_root_url(subdomain: "login"))
    end

    it "responde com sucesso ainda que o e-mail não exista" do
      post "/forgot_password", params: { email: "inexistente@example.com" }

      expect(response).to redirect_to(login_root_url(subdomain: "login"))
    end
  end

  describe "GET /new_password" do
    it "renderiza o formulário de nova senha" do
      get "/new_password"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PUT /new_password" do
    it "atualiza a senha quando o token é válido" do
      user = create(:user, :gestor, active: false, password: "Password@123")
      raw_token = user.send(:set_reset_password_token)

      put "/new_password", params: {
        reset_password_token: raw_token,
        password: "NovaSenha@123",
        password_confirmation: "NovaSenha@123"
      }

      expect(response).to redirect_to(login_root_url(subdomain: "login"))
      expect(user.reload.active?).to be(true)
    end

    it "re-renderiza o formulário quando o token é inválido" do
      put "/new_password", params: {
        reset_password_token: "invalido",
        password: "NovaSenha@123",
        password_confirmation: "NovaSenha@123"
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /confirm_signup" do
    it "ativa a conta quando o token é válido" do
      user = create(:user, :gestor, active: false)
      token = user.signed_id(purpose: :signup_confirmation, expires_in: 24.hours)

      get "/confirm_signup", params: { token: token }

      expect(response).to redirect_to(login_root_url(subdomain: "login"))
      expect(user.reload.active?).to be(true)
    end

    it "alerta quando o token é inválido" do
      get "/confirm_signup", params: { token: "totalmente-invalido" }

      expect(response).to redirect_to(login_root_url(subdomain: "login"))
      follow_redirect!
      expect(flash[:alert] || response.body).to be_present
    end
  end

  describe "DELETE /logout" do
    it "encerra sessão de usuário autenticado" do
      user = create(:user, :admin, active: true)
      sign_in user

      delete "/logout"

      expect(response).to redirect_to(login_root_url(subdomain: "login"))
      expect(Audit::AuthLogger).to have_received(:logout_succeeded).with(user: user)
    end

    it "lida com logout sem usuário autenticado" do
      delete "/logout"

      expect(response).to redirect_to(login_root_url(subdomain: "login"))
    end
  end

  def active_company
    plan = create(:plan)
    company = create(:company, plan: plan, active: true, terms_version_accepted: TermsOfUse.current_version, terms_accepted_at: Time.current)
    create(:subscription, company: company, subscription_plan: plan, status: :active)
    company
  end

  def scoped_host_for(subdomain)
    ([subdomain] + Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app") + ["example", "com"]).join(".")
  end
end
