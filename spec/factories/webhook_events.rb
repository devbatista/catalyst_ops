FactoryBot.define do
  factory :webhook_event do
    provider { WebhookEvent::PROVIDER_MERCADO_PAGO }
    sequence(:event_key) { |n| "event_#{n}" }
    resource_id { "pay_123" }
    event_type { "payment" }
    status { "received" }
    payload { { "type" => "payment", "data" => { "id" => resource_id } } }
  end
end
