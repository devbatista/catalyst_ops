FactoryBot.define do
  factory :order_service do
    association :client
    association :company
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    status { :agendada }
    scheduled_at { 1.day.from_now }
  end
end