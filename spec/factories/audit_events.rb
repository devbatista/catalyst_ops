FactoryBot.define do
  factory :audit_event do
    occurred_at { Time.current }
    action { "plan.created" }
    source { "system" }
    metadata { { "event" => "created" } }
  end
end
