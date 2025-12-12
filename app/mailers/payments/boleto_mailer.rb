class Payments::BoletoMailer < ApplicationMailer
  default from: "no-reply@catalystops.com"

  def ticket_email
    @company  = params[:company]
    @url      = params[:boleto_url]
    @barcode  = params[:boleto_barcode]
    @expires_on = params[:boleto_expiration_date]
    @status   = params[:payment_status]

    mail(
      to: @company.email,
      subject: "Seu boleto CatalystOps"
    )
  end
end