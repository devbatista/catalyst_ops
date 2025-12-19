class Payments::BoletoPaymentJob < ApplicationJob
  queue_as :default

  def perform(company_id)
    company = Company.find_by(id: company_id)
    
    Cmd::MercadoPago::CreateBoletoPayment.new(
      company: company
    ).call
  end
end