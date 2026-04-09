module Reports
  class GenerateExportJob < ApplicationJob
    queue_as :default

    def perform(report_id)
      report = Report.find_by(id: report_id)
      return if report.blank?

      report.update!(status: :processing, error_message: nil)
      Audit::Log.call(
        action: "report.export.processing",
        actor: report.user,
        company: report.company,
        resource: report,
        metadata: {
          report_id: report.id,
          report_type: report.report_type,
          filters: report.filters
        }
      )

      result = Reports::ExportBuilder.call(report)

      report.update!(
        status: :finished,
        generated_at: Time.current,
        file: result[:output_path],
        error_message: nil
      )

      Audit::Log.call(
        action: "report.export.completed",
        actor: report.user,
        company: report.company,
        resource: report,
        metadata: {
          report_id: report.id,
          report_type: report.report_type,
          generated_at: report.generated_at,
          file: report.file
        }
      )
    rescue StandardError => e
      report&.update(
        status: :failed,
        error_message: e.message.truncate(1000)
      )
      Audit::Log.call(
        action: "report.export.failed",
        actor: report&.user,
        company: report&.company,
        resource: report,
        metadata: {
          report_id: report&.id,
          report_type: report&.report_type,
          error_class: e.class.name,
          error_message: e.message
        }
      )
      raise
    end
  end
end
