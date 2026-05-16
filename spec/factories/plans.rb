FactoryBot.define do
  factory :plan do
    name { "Basico" }
    reason { "c-basico" }
    status { "active" }
    sequence(:external_id) { |n| "plan_#{n}" }
    sequence(:external_reference) { |n| "PLAN_#{n}" }
    frequency { 1 }
    frequency_type { "months" }
    transaction_amount { 99.0 }

    trait :profissional do
      name { "Profissional" }
      reason { "c-profissional" }
      external_reference { "PROFISSIONAL_#{SecureRandom.hex(4)}" }
      transaction_amount { 199.0 }
    end

    trait :enterprise do
      name { "Enterprise" }
      reason { "c-enterprise" }
      external_reference { "ENTERPRISE_#{SecureRandom.hex(4)}" }
      transaction_amount { 399.0 }
    end
  end
end
