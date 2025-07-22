class App::ClientsController < ApplicationController
  load_and_authorize_resource
  
  def index
    @clients = @clients.includes(:order_services)
                       .order(:name)
                       .page(params[:page])
  end

  def show
    @order_services = @client.order_services
                             .includes(:users)
                             .order(created_at: :desc)
  end

  def new;end

  def create
    if @client.save
      redirect_to @client, notice: 'Cliente criado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to @client, notice: 'Cliente atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to clients_path, notice: 'Cliente removido com sucesso.'
  end

  private

  def client_params
    params.require(:client).permit(:name, :document, :email, :phone, :address)
  end
end