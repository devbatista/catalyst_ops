class Subscriptions::ExpirationMailer < ApplicationMailer
  def expired_email
    @subscription = params[:subscription]
    @company = @subscription.company
    @plan = @subscription.plan
    @responsible_name = @company.responsible&.name.presence || @company.name
    @expired_on = @subscription.expired_date || Time.current

    mail(
      to: recipient_email,
      subject: "Assinatura expirada - #{@company.name}"
    )
  end

  private

  def recipient_email
    @company.responsible&.email.presence || @company.email
  end
end
