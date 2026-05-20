FactoryBot.define do
  factory :subscription_reconciliation_event do
    transient do
      subscription_plan { create(:plan) }
    end

    subscription { association(:subscription, subscription_plan: subscription_plan) }
    company { subscription.company }
    source_job { "subscription_reconciliation" }
    window_days { 30 }
    payment_method { "pix" }
    sequence(:gateway_identifier) { |n| "payment_#{n}" }
    gateway_status { "approved" }
    local_status_before { "pending" }
    local_status_after { "active" }
    divergent { false }
    resolved { true }
    result_status { "success" }
    raw_payload { { "status" => gateway_status } }
    processed_at { Time.current }
  end
end
