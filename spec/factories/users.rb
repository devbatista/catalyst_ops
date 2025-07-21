FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    name { Faker::Name.name }
    role { "tecnico" }

    trait :admin do
      role { "admin" }
    end

    trait :gestor do
      role { "gestor" }
    end

    trait :tecnico do
      role { "tecnico" }
    end
  end
end