class ServiceItemsController < ApplicationController
  before_action :set_order_service
  before_action :set_service_item, only: [:show, :edit, :update, :destroy]
  
  def new
    @service_item = @order_service.service_items.build
    authorize! :create, @service_item
  end

  def create
    @service_item = @order_service.service_items.build(service_item_params)
    authorize! :create, @service_item
    
    if @service_item.save
      redirect_to @order_service, notice: 'Item de serviço adicionado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize! :update, @service_item
  end

  def update
    authorize! :update, @service_item
    
    if @service_item.update(service_item_params)
      redirect_to @order_service, notice: 'Item de serviço atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @service_item
    @service_item.destroy
    redirect_to @order_service, notice: 'Item de serviço removido com sucesso.'
  end

  private

  def set_order_service
    @order_service = OrderService.find(params[:order_service_id])
  end

  def set_service_item
    @service_item = @order_service.service_items.find(params[:id])
  end

  def service_item_params
    params.require(:service_item).permit(:description, :quantity, :unit_price)
  end
end