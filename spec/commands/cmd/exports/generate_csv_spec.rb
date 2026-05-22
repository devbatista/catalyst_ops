require "rails_helper"

RSpec.describe Cmd::Exports::GenerateCsv do
  describe "#call" do
    it "gera CSV com template de logs administrativos" do
      company = create(:company, name: "Empresa Teste")
      event = create(:audit_event, company: company, action: "plan.created", metadata: { "event" => "created" })

      result = described_class.new(collection: AuditEvent.where(id: event.id), template: :admin_logs).call

      expect(result).to be_success
      expect(result.csv).to include("occurred_at,action,source")
      expect(result.csv).to include(event.id)
      expect(result.csv).to include("Empresa Teste")
    end

    it "gera CSV com cabeçalhos e bloco customizados" do
      result = described_class.new(collection: [1, 2], headers: ["dobro"]) { |value| [value * 2] }.call

      expect(result).to be_success
      expect(result.csv).to eq("dobro\n2\n4\n")
    end

    it "retorna erro para template desconhecido" do
      result = described_class.new(collection: [], template: :desconhecido).call

      expect(result).not_to be_success
      expect(result.errors).to eq("template nao suportado: desconhecido")
    end

    it "retorna erro quando cabeçalhos estão ausentes" do
      result = described_class.new(collection: []) { |record| [record] }.call

      expect(result).not_to be_success
      expect(result.errors).to eq("headers e obrigatorio")
    end
  end
end
