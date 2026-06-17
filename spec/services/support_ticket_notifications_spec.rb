require "rails_helper"

RSpec.describe SupportTicketNotifications do
  let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    allow(SupportTicketMailer).to receive(:with).and_return(
      double(ticket_created: mail_delivery, ticket_updated: mail_delivery, ticket_status_changed: mail_delivery)
    )
  end

  describe ".notify_created" do
    it "notifica admins e gestores ativos sem incluir o ator" do
      ticket, actor, admin, manager = ticket_with_recipients

      described_class.notify_created(ticket: ticket, actor: actor)

      expect(SupportTicketMailer).to have_received(:with).with(
        support_ticket: ticket,
        audience: :admin,
        recipient_emails: [admin.email]
      )
      expect(SupportTicketMailer).to have_received(:with).with(
        support_ticket: ticket,
        audience: :manager,
        recipient_emails: [manager.email]
      )
      expect(mail_delivery).to have_received(:deliver_later).twice
    end
  end

  describe ".notify_message" do
    it "notifica nova mensagem" do
      ticket, actor, = ticket_with_recipients
      message = create(:support_message, support_ticket: ticket, user: actor, body: "Atualização")

      described_class.notify_message(message: message, actor: actor)

      expect(SupportTicketMailer).to have_received(:with).with(hash_including(
        support_ticket: ticket,
        support_message: message,
        actor: actor
      )).twice
    end
  end

  describe ".notify_status_changed" do
    it "notifica mudança de status" do
      ticket, actor, = ticket_with_recipients

      described_class.notify_status_changed(ticket: ticket, actor: actor, previous_status: "aberto")

      expect(SupportTicketMailer).to have_received(:with).with(hash_including(
        support_ticket: ticket,
        actor: actor,
        previous_status: "aberto"
      )).twice
    end
  end

  def ticket_with_recipients
    company = create(:company)
    actor = create(:user, :gestor, company: company, active: true, email: "ator@example.com")
    admin = create(:user, :admin, active: true, email: "admin@example.com")
    manager = create(:user, :gestor, company: company, active: true, email: "gestor@example.com")
    ticket = create(:support_ticket, company: company, user: actor)

    [ticket, actor, admin, manager]
  end
end
