require "rails_helper"

RSpec.describe ReportsHelper, type: :helper do
  describe "#report_status_badge_class" do
    it "retorna classe por status e fallback" do
      aggregate_failures do
        expect(helper.report_status_badge_class("finalizada")).to eq("primary")
        expect(helper.report_status_badge_class("cancelada")).to eq("danger")
        expect(helper.report_status_badge_class("desconhecido")).to eq("secondary")
      end
    end
  end

  describe "#report_resolution_hours" do
    it "calcula tempo de resolução quando existem início e fim" do
      order_service = build(:order_service, started_at: Time.zone.local(2026, 5, 1, 8), finished_at: Time.zone.local(2026, 5, 1, 10, 30))

      expect(helper.report_resolution_hours(order_service)).to eq("2.5h")
    end

    it "retorna traço quando datas estão incompletas" do
      expect(helper.report_resolution_hours(build(:order_service, started_at: nil, finished_at: Time.current))).to eq("-")
    end
  end

  describe "#report_sla_badge" do
    it "indica SLA dentro, fora e indisponível" do
      on_time = build(:order_service, expected_end_at: Time.zone.local(2026, 5, 1, 12), finished_at: Time.zone.local(2026, 5, 1, 11))
      late = build(:order_service, expected_end_at: Time.zone.local(2026, 5, 1, 12), finished_at: Time.zone.local(2026, 5, 1, 13))
      missing = build(:order_service, expected_end_at: nil, finished_at: Time.zone.local(2026, 5, 1, 13))

      aggregate_failures do
        expect(helper.report_sla_badge(on_time)).to include("Dentro do SLA", "badge bg-success")
        expect(helper.report_sla_badge(late)).to include("Fora do SLA", "badge bg-danger")
        expect(helper.report_sla_badge(missing)).to include("N/A", "badge bg-light text-dark border")
      end
    end
  end

  describe "#available_report_categories" do
    it "agrupa relatórios por categoria" do
      grouped = helper.available_report_categories

      aggregate_failures do
        expect(grouped).to have_key("Cadastros")
        expect(grouped).to have_key("Operacional")
        expect(grouped["Operacional"]).to include(hash_including(name: "Ordens de Serviço por Período"))
      end
    end
  end
end
