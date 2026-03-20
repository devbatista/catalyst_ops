class Subscriptions::ExpirationWarningMailer < ApplicationMailer
  def warning_email
    @subscription = params[:subscription]
    @company = @subscription.company
    @plan = @subscription.plan
    @expired_on = @subscription.end_date
    @expires_in_days = 5

    mail(
      to: @company.email,
      subject: "Sua assinatura CatalystOps está vencida"
    )
  end
end
