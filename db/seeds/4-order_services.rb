require "faker"

puts "Criando ordens de serviço"

ORDER_SERVICES = []
CLIENTS.each do |client|
  rand(3..10).times do
    os = OrderService.create!(
      title: Faker::Commerce.product_name,
      description: Faker::Lorem.sentence(word_count: 8),
      client: client,
      company: client.company
    )
    ORDER_SERVICES << os
  end
end

puts "OS criadas"
puts "###################################"