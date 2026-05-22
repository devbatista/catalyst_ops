require "rails_helper"

RSpec.describe Exports::CsvBuilder do
  describe ".call" do
    it "gera CSV com cabeçalhos e linhas de coleção comum" do
      csv = described_class.call(headers: ["id", "nome"], collection: [[1, "Ana"], [2, "Bia"]]) do |row|
        row
      end

      expect(csv).to eq("id,nome\n1,Ana\n2,Bia\n")
    end

    it "gera apenas cabeçalho quando não há registros" do
      csv = described_class.call(headers: ["id"], collection: []) { |row| row }

      expect(csv).to eq("id\n")
    end

    it "usa find_each para relações ActiveRecord" do
      first = create(:audit_event, action: "plan.created")
      second = create(:audit_event, action: "plan.updated")

      csv = described_class.call(headers: ["action"], collection: AuditEvent.where(id: [first.id, second.id]).order(:created_at), batch_size: 1) do |event|
        [event.action]
      end

      expect(csv.lines).to contain_exactly("action\n", "plan.created\n", "plan.updated\n")
    end

    it "exige bloco para montar as linhas" do
      expect do
        described_class.call(headers: ["id"], collection: [])
      end.to raise_error(ArgumentError, "row_builder block is required")
    end
  end
end
