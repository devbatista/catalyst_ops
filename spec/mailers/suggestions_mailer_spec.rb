require "rails_helper"

RSpec.describe SuggestionsMailer, type: :mailer do
  describe "#submit_suggestion" do
    it "envia sugestão para destinatário configurado" do
      user = create(:user, :gestor)
      company = create(:company)
      suggestion = { title: "Melhoria no calendário", description: "Adicionar filtros por técnico." }

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("SUGGESTIONS_RECIPIENT_EMAIL", "contato@catalystops.com.br").and_return("produto@example.com")

      mail = described_class.submit_suggestion(user: user, company: company, suggestion: suggestion)

      aggregate_failures do
        expect(mail.to).to eq(["produto@example.com"])
        expect(mail.subject).to eq("Nova sugestao CatalystOps: Melhoria no calendário")
        expect(mail.text_part.decoded).to include("Adicionar filtros por técnico.")
      end
    end
  end
end
