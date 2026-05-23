class Admin::CoverageController < AdminController
  def index
    @coverage_report = coverage_report
    @coverage_report_path = "/coverage_report/index.html"
  end

  private

  def coverage_report
    last_run_path = Rails.root.join("coverage/.last_run.json")
    resultset_path = Rails.root.join("coverage/.resultset.json")

    return unless File.exist?(last_run_path)

    result = JSON.parse(File.read(last_run_path)).fetch("result", {})

    {
      line: result["line"],
      branch: result["branch"],
      updated_at: File.mtime(last_run_path),
      resultset_exists: File.exist?(resultset_path),
      report_exists: File.exist?(Rails.root.join("coverage/index.html"))
    }
  rescue JSON::ParserError
    nil
  end
end
