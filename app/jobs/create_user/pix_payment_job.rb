class CreateUser::PixPaymentJob < ApplicationJob
  queue_as :default

  def perform(company_id)
    company = Company.find(company_id)

    result = Cmd::MercadoPago::CreatePixPayment.new(company).call

    if result.success?
      company.subscriptions
             .pending
             .order(created_at: :desc)
             .first
             .update!(external_reference: result.mailer_params[:external_id])

      Payments::PixMailer.with(result.mailer_params).pix_email.deliver_later
      Rails.logger.info("[CreateUser::PixPaymentJob] E-mail de pagamento Pix enviado para Company ID #{company_id}.")
    else
      Rails.logger.error("[CreateUser::PixPaymentJob] Falha ao criar pagamento Pix para Company ID #{company_id}: #{result.errors}")
    end
  end
end