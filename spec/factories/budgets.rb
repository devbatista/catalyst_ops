FactoryBot.define do
  factory :budget do
    association :company
    association :client
    title { "Orçamento de manutenção" }
    description { "Serviços previstos para manutenção preventiva." }
    code { 1 }
    total_value { 100.0 }
    estimated_delivery_days { 5 }
  end
end
