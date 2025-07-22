FactoryBot.define do
  factory :company do
    name { "Empresa Exemplo" }
    document { CPF.generate }
    email { Faker::Internet.email }
    phone { "11999999999" }
    address { Faker::Address.full_address }
    responsible { nil }
  end
end