class Payments::PixPaymentJob < ApplicationJob
  queue_as :default

  def perform(company_id)
    Cmd::MercadoPago::CreatePixPayment.new(
      company: company
    ).call
  end
end