class CreateUser::BoletoPaymentJob < ApplicationJob
  queue_as :default

  def perform(company_id)
    company = Company.find_by(id: company_id)
    
    result = Cmd::MercadoPago::CreateBoletoPayment.new(company).call

    if result.success?
      company.current_subscription.update!(external_reference: result.mailer_params[:external_id])

      Payments::BoletoMailer.with(result.mailer_params).ticket_email.deliver_later
      Rails.logger.info("[CreateUser::BoletoPaymentJob] E-mail de pagamento boleto enviado para Company ID #{company_id}.")
    else
      Rails.logger.error("[CreateUser::BoletoPaymentJob] Falha ao criar pagamento boleto para Company ID #{company_id}: #{result.errors}")
    end
  end
end