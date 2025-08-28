class OrderServiceMailer < ApplicationMailer
  def notify_create(order_service)
    @order_service = order_service
    @client = @order_service.client
    mail(to: @client.email, subject: "Uma nova Ordem de Serviço foi criada!")
  end

  def notify_scheduled(order_service)
    @order_service = order_service
    @client = @order_service.client
    mail(to: @client.email, subject: "Sua ordem de serviço foi atribuída e agendada!")
  end
end
