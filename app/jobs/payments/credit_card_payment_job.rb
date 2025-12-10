class Payment::CreditCardPaymentJob < ApplicationJob
  queue_as :default

  def perform(company_id, user_id)
     
  end
end