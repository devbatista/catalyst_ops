class CreateUser::CreditCardPaymentJob < ApplicationJob
  queue_as :default

  def perform(company_id, cc_token)
    company = Company.find_by(id: company_id)
    unless company
      Rails.logger.error("Company with id #{company_id} not found.")
      return
    end

    Cmd::MercadoPago::CreateCreditCardPayment.new(company, cc_token).call
  end
end
