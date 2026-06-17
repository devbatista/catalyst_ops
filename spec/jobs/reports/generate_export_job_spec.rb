require "rails_helper"

RSpec.describe Reports::GenerateExportJob, type: :job do
  let(:company) { create(:company) }
  let(:user) { create(:user, :gestor, company: company, active: true) }
  let(:report) { create(:report, company: company, user: user, report_type: :service_orders, filters: { "export_format" => "csv" }) }

  before do
    allow(Audit::Log).to receive(:call)
  end

  it "não faz nada quando o relatório não existe" do
    expect(Reports::ExportBuilder).not_to receive(:call)

    described_class.perform_now(SecureRandom.uuid)
  end

  it "gera exportação e marca relatório como finalizado" do
    output_path = Rails.root.join("tmp", "reports", "report.csv").to_s

    allow(Reports::ExportBuilder).to receive(:call).with(report).and_return(output_path: output_path, content_type: "text/csv; charset=utf-8")

    described_class.perform_now(report.id)

    aggregate_failures do
      expect(report.reload).to be_status_finished
      expect(report.generated_at).to be_present
      expect(report.file).to eq(output_path)
      expect(report.error_message).to be_nil
      expect(Audit::Log).to have_received(:call).with(hash_including(action: "report.export.processing"))
      expect(Audit::Log).to have_received(:call).with(hash_including(action: "report.export.completed"))
    end
  end

  it "marca relatório como falho quando a exportação levanta erro" do
    allow(Reports::ExportBuilder).to receive(:call).and_raise(StandardError, "falha ao gerar arquivo")

    expect do
      described_class.perform_now(report.id)
    end.to raise_error(StandardError, "falha ao gerar arquivo")

    aggregate_failures do
      expect(report.reload).to be_status_failed
      expect(report.error_message).to eq("falha ao gerar arquivo")
      expect(Audit::Log).to have_received(:call).with(hash_including(action: "report.export.failed"))
    end
  end
end
