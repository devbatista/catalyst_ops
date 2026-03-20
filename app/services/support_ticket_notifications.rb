class SupportTicketNotifications
  AUDIENCES = %i[admin manager].freeze

  class << self
    def notify_created(ticket:, actor:)
      AUDIENCES.each do |audience|
        recipients = recipients_for(ticket: ticket, audience: audience, actor: actor)
        next if recipients.empty?

        SupportTicketMailer.with(
          support_ticket: ticket,
          audience: audience,
          recipient_emails: recipients
        ).ticket_created.deliver_later
      end
    end

    def notify_message(message:, actor:)
      ticket = message.support_ticket

      AUDIENCES.each do |audience|
        recipients = recipients_for(ticket: ticket, audience: audience, actor: actor)
        next if recipients.empty?

        SupportTicketMailer.with(
          support_ticket: ticket,
          support_message: message,
          actor: actor,
          audience: audience,
          recipient_emails: recipients
        ).ticket_updated.deliver_later
      end
    end

    def notify_status_changed(ticket:, actor:, previous_status:)
      AUDIENCES.each do |audience|
        recipients = recipients_for(ticket: ticket, audience: audience, actor: actor)
        next if recipients.empty?

        SupportTicketMailer.with(
          support_ticket: ticket,
          actor: actor,
          previous_status: previous_status,
          audience: audience,
          recipient_emails: recipients
        ).ticket_status_changed.deliver_later
      end
    end

    private

    def recipients_for(ticket:, audience:, actor:)
      emails = case audience
      when :admin
        User.admin.active.where.not(email: [ nil, "" ]).pluck(:email)
      when :manager
        ticket.company.gestores.active.where.not(email: [ nil, "" ]).pluck(:email)
      else
        []
      end

      emails.reject { |email| email == actor&.email }.uniq
    end
  end
end
