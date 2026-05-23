require "rails_helper"

RSpec.describe "App::ReportsController", type: :request do
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
  let!(:subscription) { create(:subscription, company: company, subscription_plan: plan, status: :active) }
  let(:user) { create(:user, :gestor, company: company, active: true) }

  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)
    allow(Reports::GenerateExportJob).to receive(:perform_later)
    allow(Audit::Log).to receive(:call)

    host! scoped_host_for("app")
    sign_in user
  end

  it "cria solicitação de exportação com filtros normalizados" do
    expect do
      post "/reports/export", params: {
        report_source: "budgets",
        export_format: "xlsx",
        group_by: "month",
        start_date: "2026-01-01",
        end_date: "2026-01-31",
        status: "aprovado"
      }
    end.to change(Report, :count).by(1)

    report = Report.last

    aggregate_failures do
      expect(response).to redirect_to(app_reports_path(report_source: "budgets", group_by: "month", start_date: "2026-01-01", end_date: "2026-01-31", status: "aprovado"))
      expect(report.title).to eq("Relatório de Orçamentos (XLSX)")
      expect(report).to be_report_type_budgets
      expect(report.filters).to include(
        "report_source" => "budgets",
        "group_by" => "month",
        "start_date" => "2026-01-01",
        "end_date" => "2026-01-31",
        "status" => "aprovado",
        "export_format" => "xlsx"
      )
      expect(Reports::GenerateExportJob).to have_received(:perform_later).with(report.id)
      expect(Audit::Log).to have_received(:call).with(hash_including(action: "report.export.requested", resource: report))
    end
  end

  it "redireciona download quando arquivo do relatório ainda não existe" do
    report = create(:report, company: company, user: user, status: :pending)

    get "/reports/#{report.id}"

    aggregate_failures do
      expect(response).to redirect_to(app_reports_path)
      expect(flash[:alert]).to eq("Arquivo do relatório ainda não está disponível para download.")
    end
  end

  it "limita período máximo no índice" do
    get "/reports", params: {
      start_date: "2025-01-01",
      end_date: "2026-01-01"
    }

    aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(flash[:alert]).to include("O período máximo permitido é de 6 meses")
    end
  end

  def scoped_host_for(subdomain)
    ([subdomain] + Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app") + ["example", "com"]).join(".")
  end
end
