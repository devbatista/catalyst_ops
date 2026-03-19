class SuggestionsMailer < ApplicationMailer
  def submit_suggestion(user:, company:, suggestion:)
    @user = user
    @company = company
    @suggestion = suggestion

    mail(
      to: suggestion_recipient,
      subject: "Nova sugestao CatalystOps: #{@suggestion[:title]}",
    )
  end

  private

  def suggestion_recipient
    ENV.fetch("SUGGESTIONS_RECIPIENT_EMAIL", "suporte@catalystops.com.br")
  end
end
