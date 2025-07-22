ASSIGNMENTS = []

puts 'Atribuindo técnicos às OSs'

ORDER_SERVICES.each do |os|
  # Seleciona técnicos da mesma empresa do cliente
  tecnicos = USERS.select { |u| u.role == "tecnico" && u.company_id == os.company_id }
  next if tecnicos.empty?

  # Filtra técnicos que já têm OS agendada para o mesmo dia
  disponiveis = tecnicos.select do |tecnico|
    os_do_tecnico = Assignment.joins(:order_service)
      .where(user_id: tecnico.id)
      .where(order_services: { scheduled_at: os.scheduled_at.beginning_of_day..os.scheduled_at.end_of_day })
    os_do_tecnico.empty?
  end

  next if disponiveis.empty?

  # Atribui 1 a 3 técnicos disponíveis por OS
  disponiveis.sample(rand(1..[3, disponiveis.size].min)).each do |tecnico|
    ASSIGNMENTS << Assignment.create!(
      user: tecnico,
      order_service: os
    )
  end
end

puts 'Técnicos atribuídos!'
puts '###################################'