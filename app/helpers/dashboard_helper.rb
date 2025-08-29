module DashboardHelper
  def status_color_for(status)
    OrderService.new(status: status).status_color
  end

  def weekly_change_indicator(current_value, previous_value)
    return content_tag(:p, "—", class: "mb-0 font-13") if previous_value&.zero?
    
    percentage = ((current_value - previous_value) / previous_value.to_f) * 100
    
    css_class = percentage >= 0 ? "text-success" : "text-danger"
    icon = percentage >= 0 ? "bx-up-arrow-alt" : "bx-down-arrow-alt"
    
    content_tag(:p, class: "mb-0 font-13 #{css_class}") do
      concat content_tag(:i, "", class: "bx #{icon} align-middle")
      concat " #{number_to_percentage(percentage.abs, precision: 1)} da última semana"
    end
  end
end
