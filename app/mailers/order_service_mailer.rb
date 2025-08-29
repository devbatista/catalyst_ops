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

  def notify_manager_on_complete(order_service)
    @order_service = order_service
    @client = @order_service.client
    manager_emails = @order_service.company.gestores.pluck(:email)
    mail(to: manager_emails, subject: "OS concluída e aguarda finalização!")
  end

  def notify_client_on_complete(order_service)
    @order_service = order_service
    @client = @order_service.client
    mail(to: @client.email, subject: "Sua ordem de serviço foi concluída com sucesso!")
  end
end
