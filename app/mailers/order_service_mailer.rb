class OrderServiceMailer < ApplicationMailer
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

  def notify_client_on_finished(order_service)
    @order_service = order_service
    @client = @order_service.client
    mail(to: @client.email, subject: "Sua ordem de serviço foi finalizada!")
  end

  def notify_overdue(order_service)
    @order_service = order_service
    @gestor = @order_service.company.responsible
    @responsible_email = @gestor.email
    mail(to: @responsible_email, subject: "A ordem de serviço ##{@order_service.code} está atrasada!")
  end

  def notify_technician_on_finished(order_service, user)
    @order_service = order_service
    @user = user
    mail(to: @user.email, subject: "A ordem de serviço ##{@order_service.code} foi finalizada!")
  end

  def notify_in_progress(order_service)
    @order_service = order_service
    @technicians = @order_service.users
    @gestor = @order_service.company.responsible
    mail(to: @gestor.email, subject: "A ordem de serviço ##{@order_service.code} está em andamento!")
  end

  def approval_request_to_client(order_service, token)
    @order_service = order_service
    @client = @order_service.client
    @approval_url = order_service_approval_url(token: token, subdomain: "cliente")

    mail(to: @client.email, subject: "Aprovação da Ordem de Serviço ##{@order_service.code}")
  end

  def approval_request_copy_to_manager(order_service, manager_email)
    @order_service = order_service
    @client = @order_service.client

    pdf_data = Cmd::Pdf::Create.new(@order_service).generate_pdf_data
    attachments["ordem_servico_#{@order_service.code}.pdf"] = {
      mime_type: "application/pdf",
      content: pdf_data
    }

    mail(to: manager_email, subject: "Cópia da OS ##{@order_service.code} para envio ao cliente")
  end

  def notify_client_on_approval(order_service)
    @order_service = order_service
    @client = @order_service.client
    mail(to: @client.email, subject: "Ordem de Serviço ##{@order_service.code} aprovada")
  end
end
