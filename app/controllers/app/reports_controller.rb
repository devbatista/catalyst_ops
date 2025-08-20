class App::ReportsController < ApplicationController
  load_and_authorize_resource
  
  def index
    @reports = @reports.order(created_at: :desc)
  end

  def show
    redirect_to @report.file.url, allow_other_host: true
  end

  def service_orders
    authorize! :read, ServiceOrder

    @service_orders = current_company.service_orders

    if params[:start_date].present? && params[:end_date].present?
      @start_date = Date.parse(params[:start_date])
      @end_date = Date.parse(params[:end_date])
      @service_orders = @service_orders.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
    end

    if params[:status].present?
      @status = params[:status]
      @service_orders = @service_orders.where(status: @status)
    end

    @service_orders = @service_orders.none unless request.post?
  end
end