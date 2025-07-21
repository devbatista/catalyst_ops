FactoryBot.define do
  factory :assignment do
    association :user
    association :order_service
  end
end