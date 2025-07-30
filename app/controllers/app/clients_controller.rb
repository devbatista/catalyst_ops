class App::ClientsController < ApplicationController
  load_and_authorize_resource

  before_action :set_company, only: [:create, :update]

  def index
    per_page = params[:per].presence || 10
    @clients = @clients.search(params[:q]).page(params[:page]).per(per_page)
  end

  def show
    @order_services = @client.order_services
                             .includes(:users)
                             .order(created_at: :desc)
  end

  def new
    @client = Client.new.tap { |c| c.addresses.build }
  end

  def create
    if @client.save
      redirect_to app_clients_url, notice: "Cliente criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to app_clients_url, notice: "Cliente atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to app_clients_path, notice: "Cliente removido com sucesso."
  end

  private

  def client_params
    params.require(:client).permit(
      :name, :document, :email, :phone,
      addresses_attributes: [
        :id, :street, :number, :complement,
        :neighborhood, :zip_code, :city,
        :state, :country, :address_type, :_destroy
      ]
    )
  end

  def set_company
    @client.company = current_user.company if @client
  end
end
