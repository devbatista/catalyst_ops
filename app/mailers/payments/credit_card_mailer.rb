class Payments::CreditCardMailer < ApplicationMailer
  def credit_card_email
    @company  = params[:company]
    @payment_url = params[:payment_url]
    @plan = params[:plan]

    mail(
      to: @company.email,
      subject: "Seu código PIX CatalystOps"
    )
  end
end
