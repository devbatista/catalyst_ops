require 'faker'

puts 'Criando ordens de serviço'

ORDER_SERVICES = []

CLIENTS.each do |client|
  rand(3..10).times do
    ORDER_SERVICES << OrderService.create!(
      title: Faker::Commerce.product_name,
      description: Faker::Lorem.sentence(word_count: 8),
      client: client,
      status: OrderService.statuses.keys.sample,
      scheduled_at: Faker::Time.forward(days: 10, period: :morning),
      company: client.company
    )
  end
end

puts 'OS criadas'
puts '###################################'