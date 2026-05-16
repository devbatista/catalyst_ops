FactoryBot.define do
  factory :company do
    name { "Empresa Exemplo" }
    document { CPF.generate }
    email { Faker::Internet.email }
    phone { "11999999999" }
    street { Faker::Address.street_name }
    number { "123" }
    neighborhood { Faker::Address.community }
    city { Faker::Address.city }
    state { "SP" }
    zip_code { "01001000" }
    responsible { nil }
  end
end
