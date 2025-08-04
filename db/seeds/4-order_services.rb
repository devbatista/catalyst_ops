require "faker"

puts "Criando ordens de serviço"

ORDER_SERVICES = []

CLIENTS.each do |client|
  rand(3..10).times do
    os = OrderService.create!(
      title: Faker::Commerce.product_name,
      description: Faker::Lorem.sentence(word_count: 8),
      client: client,
      status: "agendada",
      scheduled_at: Faker::Time.forward(days: 10, period: :morning),
      company: client.company,
    )
    ORDER_SERVICES << os
  end
end

puts "OS criadas"
puts "Atualizando status e atribuindo técnicos..."
puts "###################################"

agendada_status = OrderService.statuses["agendada"]

ORDER_SERVICES.sample(ORDER_SERVICES.size / 2).each do |os|
  technicians = User.where(company: os.company, role: :tecnico)
  next if technicians.empty?

  available_techs = technicians.select do |tech|
    tech.assignments
      .joins(:order_service)
      .where.not(order_services: { status: [:concluida, :cancelada] })
      .where.not(order_services: { id: os.id })
      .where(order_services: {
        scheduled_at: os.scheduled_at.beginning_of_day..os.scheduled_at.end_of_day
      }).empty?
  end

  next if available_techs.empty?

  tech = available_techs.sample
  os.users << tech
  novo_status = %w[em_andamento concluida finalizada].sample
  os.update(status: novo_status)
end

puts "Status e técnicos atualizados!"
puts "###################################"
