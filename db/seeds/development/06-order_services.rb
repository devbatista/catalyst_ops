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

cancelled_orders = (ORDER_SERVICES - scheduled_orders).sample((ORDER_SERVICES.size * 0.2).to_i)
cancelled_orders.each do |os|
  os.update!(status: :cancelada)
end

puts "OS criadas automaticamente a partir de orçamento: #{ORDER_SERVICES.size}"
puts "OS agendadas: #{scheduled_orders.size}"
puts "OS canceladas: #{cancelled_orders.size}"
puts "###################################"
