require "rails_helper"
require "csv"

RSpec.describe Reports::ExportBuilder do
  let(:company) { company_with_active_subscription }
  let(:user) { create(:user, :gestor, company: company, active: true) }
  let(:client) { create(:client, company: company, name: "Cliente Exportacao") }

  after do
    FileUtils.rm_rf(Rails.root.join("storage", "reports_exports"))
  end

  describe ".call" do
    it "gera CSV de ordens de serviço filtrado por status e técnico" do
      technician = create(:user, :tecnico, company: company, active: true)
      expected_order = create(:order_service, company: company, client: client, status: :agendada)
      expected_order.users << technician
      create(:order_service, company: company, client: client, status: :cancelada)
      report = create(
        :report,
        company: company,
        user: user,
        report_type: :service_orders,
        filters: {
          "export_format" => "csv",
          "status" => "agendada",
          "technician_id" => technician.id,
          "start_date" => Date.current.to_s,
          "end_date" => Date.current.to_s
        }
      )

      result = described_class.call(report)
      csv = CSV.read(result[:output_path])

      aggregate_failures do
        expect(result[:content_type]).to eq("text/csv; charset=utf-8")
        expect(File).to exist(result[:output_path])
        expect(csv.first).to eq(Reports::ExportBuilder::ORDER_HEADERS)
        expect(csv.flatten).to include(expected_order.code.to_s, "Cliente Exportacao", "Total OS", "1")
      end
    end

    it "gera CSV de orçamentos com resumo financeiro" do
      budget = create(:budget, company: company, client: client, status: :aprovado)
      report = create(
        :report,
        company: company,
        user: user,
        report_type: :budgets,
        filters: {
          "export_format" => "csv",
          "status" => "aprovado",
          "start_date" => Date.current.to_s,
          "end_date" => Date.current.to_s
        }
      )

      result = described_class.call(report)
      csv = CSV.read(result[:output_path])

      aggregate_failures do
        expect(csv.first).to eq(Reports::ExportBuilder::BUDGET_HEADERS)
        expect(csv.flatten).to include(budget.code.to_s, "Cliente Exportacao", "Valor total", "100.0")
      end
    end

    it "usa CSV quando o formato solicitado é inválido" do
      report = create(:report, company: company, user: user, filters: { "export_format" => "xml" })

      result = described_class.call(report)

      aggregate_failures do
        expect(result[:content_type]).to eq("text/csv; charset=utf-8")
        expect(result[:output_path]).to end_with(".csv")
      end
    end
  end

  def company_with_active_subscription
    plan = create(:plan)
    company = create(:company, plan: plan)
    create(:subscription, company: company, subscription_plan: plan, status: :active)
    company
  end
end
