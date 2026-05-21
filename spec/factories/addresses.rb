FactoryBot.define do
  factory :address do
    street { "Rua Exemplo" }
    number { "123" }
    complement { "Sala 1" }
    neighborhood { "Centro" }
    zip_code { "12345-678" }
    city { "São Paulo" }
    state { "SP" }
    country { "Brasil" }
    address_type { "principal" }
    client
  end
end
