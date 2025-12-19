class Payments::CreditCardMailer < ApplicationMailer
  default from: "no-reply@catalystops.com.br"

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