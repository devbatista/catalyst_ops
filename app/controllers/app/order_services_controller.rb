class App::OrderServicesController < ApplicationController
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
  end

  def show
    @service_items = @order_service.service_items.order(:id)
  end

  def new
    @clients = current_user.clients.order(:name)
    @technicians = current_user.company.technicians
  end

  def create
    if @order_service.save
      redirect_to app_order_services_url, notice: "Ordem de serviço criada com sucesso."
    else
      @clients = current_user.clients.order(:name)
      @technicians = current_user.company.technicians
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @clients = current_user.clients.order(:name)
    @technicians = current_user.company.technicians
    @order_service.service_items ||= []
  end

  def update
    if @order_service.update(order_service_params)
      redirect_to @order_service, notice: "Ordem de serviço atualizada com sucesso."
    else
      @clients = Client.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order_service.destroy
    redirect_to order_services_path, notice: "Ordem de serviço removida com sucesso."
  end

  def assign_technician
    user = User.find(params[:user_id])

    if @order_service.users.include?(user)
      redirect_to @order_service, alert: "Técnico já atribuído a esta OS."
    else
      @order_service.assignments.create!(user: user)
      redirect_to @order_service, notice: "Técnico #{user.name} atribuído com sucesso."
    end
  end

  def update_status
    if @order_service.update(status: params[:status])
      @order_service.update(started_at: Time.current) if params[:status] == "em_andamento"
      @order_service.update(finished_at: Time.current) if params[:status] == "concluida"

      redirect_to @order_service, notice: "Status atualizado com sucesso."
    else
      redirect_to @order_service, alert: "Erro ao atualizar status."
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
      attachments: [],
      user_ids: [],
      service_items_attributes: [
        :id, :description, :quantity, :unit_price, :_destroy,
      ],
    )
  end
end
