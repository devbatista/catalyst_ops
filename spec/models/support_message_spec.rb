require "rails_helper"

RSpec.describe SupportMessage, type: :model do
  describe "associações" do
    it { is_expected.to belong_to(:support_ticket) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validações" do
    it { is_expected.to validate_presence_of(:body) }
  end

  describe "anexos" do
    it "permite anexar arquivos" do
      message = create(:support_message)

      message.attachments.attach(
        io: StringIO.new("conteúdo do arquivo"),
        filename: "evidencia.txt",
        content_type: "text/plain"
      )

      aggregate_failures do
        expect(message.attachments).to be_attached
        expect(message.attachments.first.filename.to_s).to eq("evidencia.txt")
      end
    end
  end

  describe "callbacks" do
    it "atualiza last_reply_at do ticket após criar mensagem" do
      ticket = create(:support_ticket)
      previous_last_reply_at = 2.days.ago
      ticket.update_column(:last_reply_at, previous_last_reply_at)
      created_at = Time.zone.local(2026, 5, 17, 10, 30, 0)

      allow(Time).to receive(:current).and_return(created_at)

      create(:support_message, support_ticket: ticket, created_at: created_at)

      expect(ticket.reload.last_reply_at).to eq(created_at)
    end
  end
end
