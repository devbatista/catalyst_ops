FactoryBot.define do
  factory :service_item do
    association :order_service
    description { Faker::Lorem.sentence }
    quantity { 2.0 }
    unit_price { 50.0 }
  end
end