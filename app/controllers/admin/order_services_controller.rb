class Admin::OrderServicesController < AdminController
  before_action :set_order_service, only: [:show, :generate_pdf]
  def index
    per_page = params[:per_page] || 10
    @order_services = OrderService.order(created_at: :desc).page(params[:page]).per(per_page)
  end

  def show
    @service_items = @order_service.service_items.order(:id)
  end

  def generate_pdf
    pdf_data = Cmd::Pdf::Create.new(@order_service).generate_pdf_data

    send_data(pdf_data,
              filename: "ordem_de_servico_#{@order_service.code}.pdf",
              type: "application/pdf",
              disposition: "inline")
  end

  private

  def set_order_service
    @order_service = OrderService.find(params[:id])
  end
end