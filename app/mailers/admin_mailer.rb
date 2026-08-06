class AdminMailer < ApplicationMailer
  def test_email(recipient_email, requested_by)
    @recipient_email = recipient_email
    @requested_by = requested_by

    mail(to: @recipient_email, subject: "E-mail de teste - CatalystOps")
  end
end
