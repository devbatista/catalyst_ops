module ReportsHelper
  def available_report_categories
    report_paths = {
      clients: '#',
      technicians: '#',
      service_orders: service_orders_app_reports_path
    }

    all_reports = Report.report_types.keys.map do |report_type|
      definition = Report::DEFINITIONS[report_type]
      next unless definition

      {
        name: definition[:name],
        path: report_paths[report_type.to_sym],
        description: definition[:description],
        category: definition[:category]
      }
    end.compact

    grouped_reports = all_reports.group_by { |report| report[:category] }

    grouped_reports.transform_values do |reports|
      reports.map { |report| report.slice(:name, :path, :description) }
    end
  end
end