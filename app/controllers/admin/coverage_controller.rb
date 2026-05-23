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

    totals = coverage_totals(resultset_path)
    result = JSON.parse(File.read(last_run_path)).fetch("result", {})

    {
      line: totals.fetch(:line) { result["line"] },
      branch: totals.fetch(:branch) { result["branch"] },
      lines_covered: totals[:lines_covered],
      lines_total: totals[:lines_total],
      branches_covered: totals[:branches_covered],
      branches_total: totals[:branches_total],
      updated_at: File.mtime(last_run_path),
      resultset_exists: File.exist?(resultset_path),
      report_exists: File.exist?(Rails.root.join("coverage/index.html"))
    }
  rescue JSON::ParserError
    nil
  end

  def coverage_totals(resultset_path)
    return {} unless File.exist?(resultset_path)

    coverage = JSON.parse(File.read(resultset_path)).values.first.fetch("coverage", {})
    relevant_lines = coverage.values.flat_map { |file| file.fetch("lines", []) }.compact
    branches = coverage.values.flat_map { |file| file.fetch("branches", {}).values.flat_map(&:values) }

    {
      line: coverage_percentage(relevant_lines.count(&:positive?), relevant_lines.size),
      branch: coverage_percentage(branches.count(&:positive?), branches.size),
      lines_covered: relevant_lines.count(&:positive?),
      lines_total: relevant_lines.size,
      branches_covered: branches.count(&:positive?),
      branches_total: branches.size
    }
  end

  def coverage_percentage(covered, total)
    return 100.0 if total.zero?

    (covered.to_f / total * 100).round(2)
  end
end
