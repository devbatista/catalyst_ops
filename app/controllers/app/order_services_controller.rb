class App::OrderServicesController < ApplicationController
  before_action :set_other_resources, only: [:new, :edit, :update]
  before_action :set_attachment_on_update, only: [:update]

  load_and_authorize_resource

  def index
    @order_services = case current_user.role
    when "admin"
      @order_services.includes(:client, :users)
    when "gestor"
      @order_services.joins(:client)
                     .where(clients: { company_id: current_user.company_id })
                     .includes(:client, :users)
    when "tecnico"
      current_user.order_services.includes(:client)
    end.order(created_at: :desc).page(params[:page]).per(params[:per] || 10)

    if params[:code].present?
      @order_services = @order_services.where(code: params[:code])
    end
  end

  def show
    @service_items = @order_service.service_items.order(:id)
  end

  def unassigned
    authorize! :read, OrderService

    @order_services = current_user.company.order_services
                                          .includes(:client)
                                          .unassigned
                                          .order(created_at: :desc)
                                          .page(params[:page])
                                          .per(params[:per] || 10)
  end

  def new; end

  def create
    if @order_service.save
      redirect_to app_order_services_url, notice: "Ordem de serviço criada com sucesso."
    else
      @clients = current_user.clients.order(:name)
      @technicians = current_user.company.users
      flash.now[:alert] = @order_service.errors.full_messages
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @order_service.update(order_service_params)
      if @attachments.present?
        add_attachs
      else
        redirect_to app_order_service_url(@order_service), notice: "Ordem de serviço atualizada com sucesso."
      end
    else
      @clients = Client.order(:name)
      flash.now[:alert] = @order_service.errors.full_messages
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order_service.destroy
    redirect_to app_order_services_url, notice: "Ordem de serviço removida com sucesso."
  end

  def assign_technician
    user = User.find(params[:user_id])

    if @order_service.users.include?(user)
      redirect_to app_order_service_url(@order_service), alert: "Técnico já atribuído a esta OS."
    else
      @order_service.assignments.create!(user: user)
      redirect_to app_order_service_url(@order_service), notice: "Técnico #{user.name} atribuído com sucesso."
    end
  end

  def update_status
    if @order_service.update(status: params[:status])
      @order_service.update(started_at: Time.current) if params[:status] == "em_andamento"
      @order_service.update(finished_at: Time.current) if params[:status] == "concluida"

      redirect_to app_order_service_url(@order_service), notice: "Status atualizado com sucesso."
    else
      redirect_to app_order_service_url(@order_service), alert: @order_service.errors.full_messages
    end
  end

  def generate_pdf
    pdf_data = Cmd::Pdf::Create.new(@order_service).generate_pdf_data
    send_data pdf_data,
              filename: "ordem_servico_#{@order_service.id}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

  def purge_attachment
    attachment = @order_service.attachments.find(params[:attachment_id])
    attachment.purge

    respond_to do |format|
      format.html { redirect_to edit_app_order_service_path(@order_service), notice: "Anexo removido com sucesso." }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "attachments_#{@order_service.id}",
          partial: "app/order_services/attachments",
          locals: { order_service: @order_service },
        )
      end
    end
  end

  private

  def order_service_params
    params.require(:order_service).permit(
      :title,
      :description,
      :client_id,
      :status,
      :scheduled_at,
      :signed_by_client,
      :observations,
      attachments: [],
      user_ids: [],
      service_items_attributes: [
        :id, :description, :quantity, :unit_price, :_destroy,
      ],
    )
  end

  def set_other_resources
    @clients = current_user.clients.order(:name)
    @technicians = current_user.company.users.where("role = ? OR can_be_technician = ?", User.roles[:tecnico], true)
    @order_service&.service_items ||= []
  end

  def set_attachment_on_update
    if params[:order_service][:attachments].is_a?(Array)
      params[:order_service][:attachments].reject!(&:blank?)
      @attachments = params[:order_service].delete(:attachments)
    end
  end

  def add_attachs
    invalid_attachments = []

    @attachments.each do |file|
      @order_service.attachments.attach(file)
      @order_service.valid?

      if @order_service.errors[:attachments].any?
        last_attachment = @order_service.attachments.last
        last_attachment.purge if last_attachment.present?
        invalid_attachments << file.original_filename
      end
    end

    if invalid_attachments.any?
      @clients = Client.order(:name)
      flash.now[:alert] = @order_service.errors.full_messages
      render :edit, status: :unprocessable_entity
    else
      redirect_to app_order_service_url(@order_service), notice: "Ordem de serviço atualizada com sucesso."
    end
  end
end
