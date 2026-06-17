require "rails_helper"

RSpec.describe OrderServicesHelper, type: :helper do
  describe "#budget_status_label" do
    it "normaliza status conhecidos e usa humanize como fallback" do
      aggregate_failures do
        expect(helper.budget_status_label(double(status: "rascunho"))).to eq("pendente")
        expect(helper.budget_status_label(double(status: "rejeitada"))).to eq("rejeitado")
        expect(helper.budget_status_label(double(status: "enviado"))).to eq("enviado")
        expect(helper.budget_status_label(double(status: "aprovado"))).to eq("aprovado")
        expect(helper.budget_status_label(double(status: "cancelado"))).to eq("cancelado")
        expect(helper.budget_status_label(double(status: "em_analise"))).to eq("Em analise")
      end
    end
  end
end
