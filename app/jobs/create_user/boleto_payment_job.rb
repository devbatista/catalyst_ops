class CreateUser::BoletoPaymentJob < ApplicationJob
  queue_as :default

  def perform(company_id, coupon_id: nil, original_amount: nil, final_amount: nil, plan_id: nil, subscription_id: nil)
    company = Company.find_by(id: company_id)
    plan = Plan.find_by(id: plan_id) || company.plan
    subscription = Subscription.find_by(id: subscription_id) || company.current_subscription
    
    result = Cmd::MercadoPago::CreateBoletoPayment.new(
      company,
      amount_override: final_amount,
      plan: plan,
      subscription: subscription
    ).call

    if result.success?
      redeem_coupon(company, subscription, coupon_id, original_amount, final_amount)
      Payments::BoletoMailer.with(result.mailer_params).ticket_email.deliver_later
      Rails.logger.info("[CreateUser::BoletoPaymentJob] E-mail de pagamento boleto enviado para Company ID #{company_id}.")
    else
      Rails.logger.error("[CreateUser::BoletoPaymentJob] Falha ao criar pagamento boleto para Company ID #{company_id}: #{result.errors}")
    end
  end

  private

  def redeem_coupon(company, subscription, coupon_id, original_amount, final_amount)
    return if coupon_id.blank?

    Coupons::Redeem.call(
      coupon: Coupon.find(coupon_id),
      company: company,
      subscription: subscription,
      original_amount: original_amount,
      final_amount: final_amount
    )
  end
end
