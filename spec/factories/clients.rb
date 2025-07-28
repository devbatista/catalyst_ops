FactoryBot.define do
  factory :client do
    name { Faker::Name.name }
    document { CPF.generate }
    email { Faker::Internet.email }
    phone { '11987654321' }
    company
    
    trait :with_cnpj do
      document { CNPJ.generate }
      name { Faker::Company.name + ' LTDA' }
    end
    
    trait :individual do
      document { CPF.generate }
      name { Faker::Name.name }
    end
    
    trait :with_formatted_phone do
      phone { '(11) 98765-4321' }
    end
  end
end