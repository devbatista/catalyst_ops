module Coupons
  class Redeem
    def self.call(coupon:, company:, subscription:, original_amount:, final_amount:, applied_at: Time.current)
      return if coupon.blank?

      redemption = CouponRedemption.find_or_initialize_by(subscription: subscription)
      redemption.coupon = coupon
      redemption.company = company
      redemption.original_amount = original_amount
      redemption.discount_amount = BigDecimal(original_amount.to_s) - BigDecimal(final_amount.to_s)
      redemption.final_amount = final_amount
      redemption.applied_at = applied_at
      redemption.save!
      redemption
    end
  end
end
