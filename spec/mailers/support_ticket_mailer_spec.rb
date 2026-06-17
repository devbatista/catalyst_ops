require "rails_helper"

RSpec.describe SupportTicketMailer, type: :mailer do
  before do
    ActionMailer::Base.default_url_options[:host] = "example.com"
  end

  let(:ticket) { create(:support_ticket, subject: "Erro no painel") }

  describe "#ticket_created" do
    it "envia novo ticket para destinatários informados" do
      email = described_class.with(
        support_ticket: ticket,
        audience: :admin,
        recipient_emails: ["admin@example.com"]
      ).ticket_created

      expect(email.to).to eq(["admin@example.com"])
      expect(email.subject).to include("Novo ticket aberto")
      expect(email.body.encoded).to include("Erro no painel")
      expect(email.body.encoded).to include("admin.")
    end
  end

  describe "#ticket_updated" do
    it "inclui mensagem e ator" do
      message = create(:support_message, support_ticket: ticket, body: "Nova informação")
      actor = create(:user, :gestor, company: ticket.company, name: "Gestora")

      email = described_class.with(
        support_ticket: ticket,
        support_message: message,
        actor: actor,
        audience: :manager,
        recipient_emails: ["gestor@example.com"]
      ).ticket_updated

      expect(email.to).to eq(["gestor@example.com"])
      expect(email.subject).to include("Nova mensagem")
      expect(email.text_part.body.decoded).to include("Nova informação")
      expect(email.text_part.body.decoded).to include("Gestora")
    end
  end

  describe "#ticket_status_changed" do
    it "inclui status anterior e novo status" do
      ticket.update!(status: :em_andamento)

      email = described_class.with(
        support_ticket: ticket,
        actor: ticket.user,
        previous_status: "aberto",
        audience: :manager,
        recipient_emails: ["gestor@example.com"]
      ).ticket_status_changed

      expect(email.to).to eq(["gestor@example.com"])
      expect(email.subject).to include("Status atualizado")
      expect(email.body.encoded).to include("Aberto")
      expect(email.body.encoded).to include("Em andamento")
    end
  end
end
