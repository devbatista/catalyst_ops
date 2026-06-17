FactoryBot.define do
  factory :coupon_redemption do
    coupon
    transient do
      subscription_plan { create(:plan) }
    end
    subscription { association(:subscription, subscription_plan: subscription_plan) }
    company { subscription.company }
    original_amount { 100.0 }
    discount_amount { 10.0 }
    final_amount { 90.0 }
    applied_at { Time.current }
  end
end
