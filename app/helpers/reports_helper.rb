module ReportsHelper
  def report_status_badge_class(status)
    {
      "pendente" => "secondary",
      "agendada" => "warning",
      "em_andamento" => "info",
      "concluida" => "success",
      "finalizada" => "primary",
      "cancelada" => "danger",
      "atrasada" => "dark"
    }[status.to_s] || "secondary"
  end

  def report_resolution_hours(order_service)
    return "-" if order_service.started_at.blank? || order_service.finished_at.blank?

    "#{((order_service.finished_at - order_service.started_at) / 1.hour).round(2)}h"
  end

  def report_sla_badge(order_service)
    return content_tag(:span, "N/A", class: "badge bg-light text-dark border") if order_service.expected_end_at.blank? || order_service.finished_at.blank?

    if order_service.finished_at <= order_service.expected_end_at
      content_tag(:span, "Dentro do SLA", class: "badge bg-success")
    else
      content_tag(:span, "Fora do SLA", class: "badge bg-danger")
    end
  end

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
