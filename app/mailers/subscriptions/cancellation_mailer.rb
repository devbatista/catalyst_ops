class Subscriptions::CancellationMailer < ApplicationMailer
  def requested_email
    @subscription = params[:subscription]
    @company = @subscription.company
    @plan = @subscription.plan
    @responsible_name = @company.responsible&.name.presence || @company.name
    @requested_on = @subscription.cancel_requested_at || Time.current
    @effective_on = @subscription.cancel_effective_on
    @cancel_reason = @subscription.cancel_reason

    mail(
      to: recipient_email,
      subject: "Solicitação de cancelamento da assinatura - #{@company.name}"
    )
  end

  def cancelled_email
    @subscription = params[:subscription]
    @company = @subscription.company
    @plan = @subscription.plan
    @responsible_name = @company.responsible&.name.presence || @company.name
    @cancelled_on = @subscription.canceled_date || Time.current

    mail(
      to: recipient_email,
      subject: "Assinatura cancelada - #{@company.name}"
    )
  end

  def reactivated_email
    @subscription = params[:subscription]
    @company = @subscription.company
    @plan = @subscription.plan
    @responsible_name = @company.responsible&.name.presence || @company.name
    @reactivated_on = Time.current

    mail(
      to: recipient_email,
      subject: "Renovação da assinatura reativada - #{@company.name}"
    )
  end

  private

  def recipient_email
    @company.responsible&.email.presence || @company.email
  end
end
