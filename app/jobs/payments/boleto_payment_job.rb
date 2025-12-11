class Payments::BoletoPaymentJob < ApplicationJob
  queue_as :default

  def perform(company_id)
    company = ::Company.find(company_id)

    plan = company.plan
  end
end