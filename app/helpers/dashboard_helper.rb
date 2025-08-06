module DashboardHelper
  def status_color_for(status)
    OrderService.new(status: status).status_color
  end
end
