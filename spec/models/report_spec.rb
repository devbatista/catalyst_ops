require "rails_helper"

RSpec.describe Report, type: :model do
  describe "associações" do
    it { should belong_to(:user) }
    it { should belong_to(:company) }
  end

  describe "validações" do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_least(5).is_at_most(100) }
    it { should validate_presence_of(:report_type) }
    it { should validate_presence_of(:status) }
    it { should validate_length_of(:error_message).is_at_most(1000) }

    it "exige data de geração e arquivo quando finalizado" do
      report = build(:report, status: :finished, generated_at: nil, file: nil)

      expect(report).not_to be_valid
      expect(report.errors[:generated_at]).to be_present
      expect(report.errors[:file]).to be_present
    end
  end

  describe "métodos de apresentação" do
    it "retorna status humanizado" do
      expect(build(:report, status: :processing).status_human).to eq("Processando")
    end

    it "retorna nome humanizado do tipo de relatório" do
      expect(build(:report, report_type: :technicians).report_type_human).to eq("Relatório de Técnicos")
    end
  end

  describe "factory" do
    it "possui uma factory válida" do
      expect(build(:report)).to be_valid
    end
  end
end
