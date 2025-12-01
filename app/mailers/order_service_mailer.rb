class OrderServiceMailer < ApplicationMailer
  def notify_create(order_service)
    @order_service = order_service
    @client = @order_service.client
    mail(to: @client.email, subject: "Uma nova Ordem de Serviço foi criada!")
  end

  def notify_client_on_scheduled(order_service)
    @order_service = order_service
    @client = @order_service.client
    mail(to: @client.email, subject: "Sua ordem de serviço foi atribuída e agendada!")
  end

  def notify_technical_on_scheduled(order_service, user)
    @order_service = order_service
    @user = user
    mail(to: @user.email, subject: "ATENÇÃO, Você foi designado para a Ordem de Serviço ##{@order_service.code}")
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

  def notify_finished(order_service)
    @order_service = order_service
    @client = @order_service.client
    mail(to: @client.email, subject: "Sua ordem de serviço foi finalizada!")
  end

  def notify_overdue(order_service)
    @order_service = order_service
    @responsible_email = @order_service.company.email
    mail(to: @responsible_email, subject: "A ordem de serviço ##{@order_service.code} está atrasada!")
  end
end
