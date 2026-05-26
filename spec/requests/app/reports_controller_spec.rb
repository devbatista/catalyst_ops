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

  it "normaliza fonte e formato inválidos ao exportar" do
    expect do
      post "/reports/export", params: {
        report_source: "invalido",
        export_format: "xml",
        group_by: "invalido",
        start_date: "data-invalida",
        end_date: "2026-01-31"
      }
    end.to change(Report, :count).by(1)

    report = Report.last

    aggregate_failures do
      expect(response).to redirect_to(app_reports_path(report_source: "order_services", group_by: "day", end_date: "2026-01-31"))
      expect(report.title).to eq("Relatório de Ordens de Serviço (CSV)")
      expect(report).to be_report_type_service_orders
      expect(report.filters).to include(
        "report_source" => "order_services",
        "group_by" => "day",
        "end_date" => "2026-01-31",
        "export_format" => "csv"
      )
    end
  end

  it "redireciona exportação quando não encontra empresa" do
    user.update_column(:company_id, nil)

    post "/reports/export", params: {
      report_source: "order_services",
      export_format: "csv",
      company_id: "0"
    }

    aggregate_failures do
      expect(response).to redirect_to(app_reports_path)
      expect(flash[:alert]).to eq("Empresa não encontrada para gerar o relatório.")
      expect(Reports::GenerateExportJob).not_to have_received(:perform_later)
    end
  end

  it "redireciona com erros quando relatório exportado é inválido" do
    allow(Report).to receive(:create!).and_wrap_original do |original, *args|
      report = Report.new(*args)
      report.errors.add(:base, "Falha ao criar relatório")
      raise ActiveRecord::RecordInvalid, report
    end

    post "/reports/export", params: {
      report_source: "budgets",
      export_format: "csv",
      group_by: "month"
    }

    aggregate_failures do
      expect(response).to redirect_to(app_reports_path(report_source: "budgets", group_by: "month"))
      expect(flash[:alert]).to eq("Falha ao criar relatório")
      expect(Reports::GenerateExportJob).not_to have_received(:perform_later)
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

  it "envia arquivo de relatório disponível para download" do
    file = Tempfile.new(["relatorio", ".csv"], Rails.root.join("tmp"))
    file.write("codigo,total\n1,100\n")
    file.close
    report = create(:report, company: company, user: user, status: :finished, file: file.path, generated_at: Time.current)

    get "/reports/#{report.id}"

    aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(Audit::Log).to have_received(:call).with(hash_including(action: "report.downloaded", resource: report))
    end
  ensure
    file&.unlink
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

  it "monta relatório operacional com filtros de status, técnico e agrupamento semanal" do
    travel_to Time.zone.local(2026, 5, 18, 10, 0, 0) do
      client = create(:client, company: company, name: "Cliente Relatório Incluído")
      other_client = create(:client, company: company, name: "Cliente Relatório Ignorado")
      technician = create(:user, :tecnico, company: company, active: true, name: "Técnico Relatório")
      other_technician = create(:user, :tecnico, company: company, active: true)
      matching_order = create(:order_service, company: company, client: client, title: "OS Relatório Incluída", status: :agendada, created_at: 3.days.ago)
      create(:assignment, order_service: matching_order, user: technician)
      matching_order.update_columns(
        status: OrderService.statuses[:finalizada],
        started_at: 2.days.ago,
        finished_at: 1.day.ago,
        expected_end_at: 1.day.ago + 1.hour,
        updated_at: 1.day.ago
      )
      other_order = create(:order_service, company: company, client: other_client, title: "OS Relatório Ignorada", status: :agendada, created_at: 3.days.ago)
      create(:assignment, order_service: other_order, user: other_technician)

      get "/reports", params: {
        report_source: "order_services",
        group_by: "week",
        start_date: "2026-05-01",
        end_date: "2026-05-31",
        status: "finalizada",
        technician_id: technician.id
      }

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Técnico Relatório")
        expect(response.body).to include("Cliente Relatório Incluído")
        expect(response.body).not_to include("Cliente Relatório Ignorado")
      end
    end
  end

  it "monta relatório de orçamentos com status e agrupamento mensal" do
    travel_to Time.zone.local(2026, 5, 18, 10, 0, 0) do
      client = create(:client, company: company)
      approved_budget = create(:budget, company: company, client: client, status: :aprovado, total_value: 300, created_at: 2.days.ago)
      create(:budget, company: company, client: client, status: :rascunho, total_value: 100, created_at: 2.days.ago)

      get "/reports", params: {
        report_source: "budgets",
        group_by: "month",
        start_date: "2026-05-01",
        end_date: "2026-05-31",
        status: "aprovado"
      }

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(approved_budget.code.to_s)
        expect(response.body).to include("Orçamentos")
      end
    end
  end

  it "ignora datas, status e técnico inválidos no índice" do
    client = create(:client, company: company)
    order_service = create(:order_service, company: company, client: client, status: :agendada)

    get "/reports", params: {
      report_source: "invalido",
      group_by: "invalido",
      start_date: "data-invalida",
      end_date: "tambem-invalida",
      status: "status-invalido",
      technician_id: "999999"
    }

    aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(order_service.code.to_s)
    end
  end

  def scoped_host_for(subdomain)
    ([subdomain] + Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app") + ["example", "com"]).join(".")
  end
end
