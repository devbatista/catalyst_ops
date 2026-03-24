class Payments::PixMailer < ApplicationMailer
  def pix_email
    @company  = params[:company]
    @pix_code = params[:pix_code]
    @pix_image_url = params[:pix_image_url]
    @expires_on = params[:pix_expiration_date]
    @pix_ticket_url = params[:pix_ticket_url]

    mail(
      to: recipient_emails,
      subject: "Seu código PIX CatalystOps"
    )
  end

  private

  def recipient_emails
    [
      @company.email,
      @company.responsible&.email
    ].filter_map { |email| email.to_s.strip.downcase.presence }.uniq
  end
end
