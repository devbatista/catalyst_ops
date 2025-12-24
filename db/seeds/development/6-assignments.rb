puts 'Atribuindo técnicos às OSs e atualizando status para "agendada"'

# Pega 75% das OS criadas no arquivo anterior para tentar agendar.
orders_to_schedule = ORDER_SERVICES.sample((ORDER_SERVICES.size * 0.75).to_i)

orders_to_schedule.each do |os|
  # Seleciona técnicos da mesma empresa da OS.
  all_technicians = USERS.select { |u| (u.can_be_technician == true || u.role == "tecnico") && u.company_id == os.company_id }
  next if all_technicians.empty?

  # CRÍTICO: Define uma data de agendamento para esta OS.
  scheduled_time = Faker::Time.forward(days: 10, period: :morning)

  # Agora que temos uma data, podemos filtrar os técnicos disponíveis.
  available_technicians = all_technicians.select do |tecnico|
    # Verifica se o técnico já tem alguma OS nesse dia.
    is_busy = Assignment.joins(:order_service)
                        .where(user_id: tecnico.id)
                        .where(order_services: { scheduled_at: scheduled_time.all_day })
                        .exists?
    !is_busy # Retorna true se o técnico NÃO estiver ocupado.
  end

  next if available_technicians.empty?

  # Pega um técnico aleatório dos que estão disponíveis.
  chosen_technician = available_technicians.sample

  # Atualiza a OS com status, data e técnico, TUDO DE UMA VEZ.
  # Isso garante que a validação de disponibilidade no modelo Assignment funcione.
  os.update!(
    status: :agendada,
    scheduled_at: scheduled_time,
    users: [chosen_technician]
  )
end

puts 'Técnicos atribuídos e status atualizados!'
puts '###################################'