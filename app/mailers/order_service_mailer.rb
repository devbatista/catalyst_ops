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
    @technician = user
    mail(to: @user.email, subject: "A ordem de serviço ##{@order_service.code} foi finalizada!")
  end

  def notify_in_progress(order_service)
    @order_service = order_service
    @technicians = @order_service.users
    @gestor = @order_service.company.responsible
    mail(to: @gestor.email, subject: "A ordem de serviço ##{@order_service.code} está em andamento!")
  end

  def send_pdf_to_client(order_service, sender)
    @order_service = order_service
    @client = @order_service.client
    @sender = sender

    pdf_data = Cmd::Pdf::Create.new(@order_service).generate_pdf_data
    attachments["ordem_servico_#{@order_service.code}.pdf"] = {
      mime_type: "application/pdf",
      content: pdf_data
    }

    mail(to: @client.email, subject: "PDF da Ordem de Serviço ##{@order_service.code}")
  end

  def send_receipt_to_client(order_service, sender)
    @order_service = order_service
    @client = @order_service.client
    @sender = sender

    receipt_builder = Cmd::Pdf::CreateOrderServiceReceipt.new(@order_service, kind: :recebimento, generated_by: @sender)
    attachments[receipt_builder.filename] = {
      mime_type: "application/pdf",
      content: receipt_builder.generate_pdf_data
    }

    mail(to: @client.email, subject: "Comprovante de recebimento - OS ##{@order_service.code}")
  end

  def send_return_receipt_to_client(order_service, sender)
    @order_service = order_service
    @client = @order_service.client
    @sender = sender

    receipt_builder = Cmd::Pdf::CreateOrderServiceReceipt.new(@order_service, kind: :devolucao, generated_by: @sender)
    attachments[receipt_builder.filename] = {
      mime_type: "application/pdf",
      content: receipt_builder.generate_pdf_data
    }

    mail(to: @client.email, subject: "Comprovante de devolução - OS ##{@order_service.code}")
  end

end
