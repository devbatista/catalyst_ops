require 'faker'

puts 'Garantindo itens nas OS (sem duplicar itens já vindos de orçamento)'

ORDER_SERVICES.each do |os|
  next if os.concluida? || os.service_items.exists?

  rand(3..6).times do
    ServiceItem.create!(
      description: "#{Faker::Commerce.material} para #{Faker::Commerce.product_name}",
      quantity: rand(1..5),
      unit_price: Faker::Commerce.price(range: 50..500),
      order_service: os
    )
  end
end

puts 'Concluído'
