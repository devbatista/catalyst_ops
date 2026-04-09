require "faker"

puts "Criando ordens de serviço a partir de orçamentos aprovados"

ORDER_SERVICES = []

budgets_to_approve = BUDGETS.sample([(BUDGETS.size * 0.6).to_i, 1].max)

budgets_to_approve.each do |budget|
  next if budget.order_service.present?
  next unless budget.company.can_create_order?

  budget.send_for_approval! if budget.rascunho? || budget.rejeitado?
  order_service = budget.approve_and_create_order_service!(approver_role: [:cliente, :gestor].sample)
  ORDER_SERVICES << order_service if order_service.present?
end

# Garante ao menos uma OS criada.
fallback_budget = nil
if ORDER_SERVICES.empty? && BUDGETS.any?
  fallback_budget = BUDGETS.find { |budget| budget.order_service.blank? && budget.company.can_create_order? }
  fallback_budget ||= BUDGETS.find { |budget| budget.order_service.blank? }
end

if ORDER_SERVICES.empty? && fallback_budget.present?
  fallback_budget.send_for_approval! if fallback_budget.rascunho? || fallback_budget.rejeitado?
  order_service = fallback_budget.approve_and_create_order_service!(approver_role: :gestor)
  ORDER_SERVICES << order_service if order_service.present?
end

# Atualiza status de parte das OS para gerar cenários mais realistas.
scheduled_orders = ORDER_SERVICES.sample((ORDER_SERVICES.size * 0.4).to_i)
scheduled_orders.each do |os|
  scheduled_time = Faker::Time.forward(days: 10, period: :morning)
  os.update!(
    status: :agendada,
    scheduled_at: scheduled_time,
    expected_end_at: scheduled_time + rand(1..4).hours
  )
end

finalized_candidates = ORDER_SERVICES - scheduled_orders
finalized_orders = finalized_candidates.sample((ORDER_SERVICES.size * 0.35).to_i)
finalized_orders.each do |os|
  # Primeiro salva em estado válido para respeitar validações de agenda.
  base_time = Faker::Time.forward(days: 8, period: :morning)
  os.update!(
    status: :finalizada,
    scheduled_at: base_time,
    expected_end_at: base_time + rand(2..6).hours
  )

  # Depois retroage datas para criar histórico útil nos relatórios.
  historical_scheduled_at = Faker::Time.backward(days: 90, period: :morning)
  historical_started_at = historical_scheduled_at + rand(10..90).minutes
  historical_finished_at = historical_started_at + rand(60..240).minutes

  os.update_columns(
    scheduled_at: historical_scheduled_at,
    expected_end_at: historical_scheduled_at + rand(2..6).hours,
    started_at: historical_started_at,
    finished_at: historical_finished_at,
    updated_at: historical_finished_at
  )
end

cancelled_orders = (ORDER_SERVICES - scheduled_orders - finalized_orders).sample((ORDER_SERVICES.size * 0.2).to_i)
cancelled_orders.each do |os|
  scheduled_time = Faker::Time.backward(days: 60, period: :morning)
  os.update!(
    status: :cancelada,
    scheduled_at: scheduled_time,
    expected_end_at: scheduled_time + rand(1..5).hours
  )
end

puts "OS criadas automaticamente a partir de orçamento: #{ORDER_SERVICES.size}"
puts "OS agendadas: #{scheduled_orders.size}"
puts "OS finalizadas: #{finalized_orders.size}"
puts "OS canceladas: #{cancelled_orders.size}"
puts "###################################"
