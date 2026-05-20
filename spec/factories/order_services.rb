FactoryBot.define do
  factory :order_service do
    association :client
    company { client.company }
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    status { :agendada }
    scheduled_at { 1.day.from_now }
    expected_end_at { scheduled_at + 2.hours }
  end
end
