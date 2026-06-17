FactoryBot.define do
  factory :budget do
    client
    company { client.company }
    title { "Orçamento de manutenção" }
    description { "Serviços previstos para manutenção preventiva." }
    code { nil }
    total_value { 100.0 }
    estimated_delivery_days { 5 }

    after(:build) do |budget|
      next if budget.service_items.any?

      budget.service_items.build(
        description: "Manutenção preventiva",
        quantity: 2,
        unit_price: 50.0
      )
    end
  end
end
