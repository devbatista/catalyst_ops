class App::ReportsController < ApplicationController
  load_and_authorize_resource
  
  def index;end

  def service_orders
    @service_orders = ServiceOrder.all

    if params[:start_date].present? && params[:end_date].present?
      @start_date = Date.parse(params[:start_date])
      @end_date = Date.parse(params[:end_date])
      @service_orders = @service_orders.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
    end

    if params[:status].present?
      @status = params[:status]
      @service_orders = @service_orders.where(status: @status)
    end

    @service_orders = ServiceOrder.nine unless request.post?
  end
end