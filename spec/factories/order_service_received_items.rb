FactoryBot.define do
  factory :order_service_received_item do
    association :order_service
    name { "Notebook" }
    brand { "Dell" }
    model { "Latitude 5420" }
    serial_number { "SN123456" }
    quantity { 1 }
    condition_notes { "Equipamento recebido sem avarias aparentes." }
    reported_issue { "Nao liga." }
    accessories { "Fonte de alimentacao." }
  end
end
