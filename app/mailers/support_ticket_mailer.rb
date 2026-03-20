class SupportTicketMailer < ApplicationMailer
  def ticket_created
    load_common_attributes

    mail(
      to: recipient_emails,
      subject: "[Ticket ##{@ticket.id}] Novo ticket aberto: #{@ticket.subject}"
    )
  end

  def ticket_updated
    load_common_attributes
    @support_message = params[:support_message]
    @actor = params[:actor]

    mail(
      to: recipient_emails,
      subject: "[Ticket ##{@ticket.id}] Nova mensagem em #{ticket_subject}"
    )
  end

  def ticket_status_changed
    load_common_attributes
    @actor = params[:actor]
    @previous_status = params[:previous_status]

    mail(
      to: recipient_emails,
      subject: "[Ticket ##{@ticket.id}] Status atualizado para #{@ticket.status.humanize}"
    )
  end

  private

  def load_common_attributes
    @ticket = params[:support_ticket]
    @audience = params[:audience]
    @company = @ticket.company
    @requester = @ticket.user
    @ticket_url = @audience == :admin ? admin_ticket_url(@ticket, subdomain: "admin") : app_support_ticket_url(@ticket, subdomain: "app")
  end

  def recipient_emails
    Array(params[:recipient_emails]).compact_blank
  end

  def ticket_subject
    @ticket.subject.presence || "ticket"
  end
end
