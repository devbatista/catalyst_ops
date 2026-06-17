FactoryBot.define do
  factory :coupon do
    sequence(:code) { |n| "CUPOM#{n}" }
    name { "Cupom promocional" }
    description { "Desconto promocional para cadastro." }
    active { true }
    benefit_type { "discount" }
    discount_type { "percentage" }
    discount_value { 10 }
    max_redemptions { nil }
    redemptions_count { 0 }
    valid_from { 1.day.ago }
    valid_until { 1.month.from_now }
    first_cycle_only { true }

    trait :trial do
      benefit_type { "trial" }
      discount_type { nil }
      discount_value { nil }
      trial_frequency { 15 }
      trial_frequency_type { "days" }
    end

    trait :fixed_amount do
      discount_type { "fixed_amount" }
      discount_value { 25 }
    end
  end
end
