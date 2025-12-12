class Payments::PixMailer < ApplicationMailer
  default from: "no-reply@catalystops.com.br"

  def pix_email
    @company  = params[:company]
    @pix_code = params[:pix_code]
    @pix_image_url = params[:pix_image_url]
    @expires_on = params[:pix_expiration_date]
    @pix_ticket_url = params[:pix_ticket_url]

    mail(
      to: @company.email,
      subject: "Seu código PIX CatalystOps"
    )
  end
end