FactoryBot.define do
  factory :subscription do
    transient do
      subscription_plan { create(:plan) }
    end

    company { association(:company, plan: subscription_plan) }
    preapproval_plan_id { subscription_plan.external_id }
    reason { subscription_plan.reason }
    external_reference { company&.id }
    transaction_amount { subscription_plan.transaction_amount }
    status { "active" }
    start_date { Date.current - 1.month }
    end_date { Date.current + 15.days }
    raw_payload { {} }
  end
end
