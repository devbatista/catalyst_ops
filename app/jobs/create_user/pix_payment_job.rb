class CreateUser::PixPaymentJob < ApplicationJob
  queue_as :default

  def perform(company_id, coupon_id: nil, original_amount: nil, final_amount: nil)
    company = Company.find(company_id)

    result = Cmd::MercadoPago::CreatePixPayment.new(company, amount_override: final_amount).call

    if result.success?
      redeem_coupon(company, coupon_id, original_amount, final_amount)
      Payments::PixMailer.with(result.mailer_params).pix_email.deliver_later
      
      Rails.logger.info("[CreateUser::PixPaymentJob] E-mail de pagamento Pix enviado para Company ID #{company_id}.")
    else
      Rails.logger.error("[CreateUser::PixPaymentJob] Falha ao criar pagamento Pix para Company ID #{company_id}: #{result.errors}")
    end
  end

  private

  def redeem_coupon(company, coupon_id, original_amount, final_amount)
    return if coupon_id.blank?

    Coupons::Redeem.call(
      coupon: Coupon.find(coupon_id),
      company: company,
      subscription: company.current_subscription,
      original_amount: original_amount,
      final_amount: final_amount
    )
  end
end
