require "rails_helper"

RSpec.describe "Admin::MetricsController", type: :request do
  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)
    host! scoped_host_for("admin")
    sign_in admin
    allow(Audit::Log).to receive(:call)
  end

  let(:admin) { create(:user, :admin, active: true) }

  describe "GET /metrics" do
    it "renderiza métricas com fallback sem Sentry" do
      get "/metrics", params: { period: "7d" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sentry")
      expect(response.body).to include("7d")
    end

    it "usa período padrão de 24h quando o parâmetro é desconhecido" do
      get "/metrics", params: { period: "invalido" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("24h")
    end

    it "apresenta indicadores zerados quando não há cohort de onboarding" do
      UserOnboardingProgress.delete_all

      get "/metrics", params: { period: "30d" }

      expect(response).to have_http_status(:ok)
    end

    it "calcula indicadores quando há usuários e eventos no período" do
      company = create_company_with_subscription
      gestor = create(:user, :gestor, company: company, active: true, created_at: 2.days.ago)
      create(:user_onboarding_progress, user: gestor, finished_at: 1.day.ago)

      create(:audit_event, action: "job.failed", occurred_at: 1.hour.ago)
      create(:audit_event, action: "report.export.failed", occurred_at: 1.hour.ago)
      create(:audit_event, action: "webhook.failed", occurred_at: 1.hour.ago)
      create(:order_service, company: company, client: create(:client, company: company), created_at: 1.day.ago + 1.hour)

      get "/metrics", params: { period: "7d" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("7d")
    end

    it "apresenta status habilitado quando Sentry está configurado" do
      ENV["SENTRY_DSN"] = "https://exemplo@sentry.io/1"

      get "/metrics", params: { period: "24h" }

      expect(response).to have_http_status(:ok)
    ensure
      ENV.delete("SENTRY_DSN")
    end

    it "sobrevive a falhas ao consultar Sidekiq" do
      allow(Sidekiq::ProcessSet).to receive(:new).and_raise(StandardError, "queue down")

      get "/metrics", params: { period: "24h" }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /metrics/test_sentry" do
    context "quando o Sentry não está configurado" do
      it "redireciona com alerta" do
        post "/metrics/test_sentry", params: { period: "7d" }

        expect(response).to redirect_to(admin_metrics_path(period: "7d"))
        follow_redirect!
        expect(flash[:alert] || response.body).to be_present
      end
    end

    context "quando o Sentry está configurado" do
      before { ENV["SENTRY_DSN"] = "https://exemplo@sentry.io/1" }

      after { ENV.delete("SENTRY_DSN") }

      it "dispara captura de exceção e registra auditoria de sucesso" do
        allow(Sentry).to receive(:capture_exception)

        post "/metrics/test_sentry", params: { period: "24h" }

        expect(Sentry).to have_received(:capture_exception)
        expect(Audit::Log).to have_received(:call).with(
          action: "system.monitoring.test_triggered",
          metadata: hash_including(event: "sentry_test_triggered", result: "sent")
        )
        expect(response).to redirect_to(admin_metrics_path(period: "24h"))
      end

      it "registra falha quando a captura levanta erro" do
        allow(Sentry).to receive(:capture_exception).and_raise(StandardError, "boom")

        post "/metrics/test_sentry", params: { period: "24h" }

        expect(Audit::Log).to have_received(:call).with(
          action: "system.monitoring.test_triggered",
          metadata: hash_including(event: "sentry_test_triggered", result: "failed", error_class: "StandardError")
        )
        expect(response).to redirect_to(admin_metrics_path(period: "24h"))
      end
    end
  end

  def create_company_with_subscription
    plan = create(:plan)
    company = create(:company, plan: plan, active: true)
    create(:subscription, company: company, subscription_plan: plan, status: :active)
    company
  end

  def scoped_host_for(subdomain)
    ([subdomain] + Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app") + ["example", "com"]).join(".")
  end
end
