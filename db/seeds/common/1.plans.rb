puts "Criando os planos..."

Plan.find_or_create_by!(external_reference: "BASICO") do |plan|
  plan.name = "Basico"
  plan.reason = "c-basico"
  plan.status = "active"
  plan.external_id = "0d5ca5de0e754022b41bcb59408924c1"
  plan.frequency = 1
  plan.frequency_type = "months"
  plan.transaction_amount = 99.0
  plan.max_technicians = 1
  plan.max_orders = 25
  plan.support_level = "email"
end

Plan.find_or_create_by!(external_reference: "PROFISSIONAL") do |plan|
  plan.name = "Profissional"
  plan.reason = "c-profissional"
  plan.status = "active"
  plan.external_id = "2afd21a0af3448a8b1b56f7ef2f96ca8"
  plan.frequency = 1
  plan.frequency_type = "months"
  plan.transaction_amount = 199.0
  plan.max_technicians = 6
  plan.max_orders = 100
  plan.support_level = "prioritario"
end

Plan.find_or_create_by!(external_reference: "ENTERPRISE") do |plan|
  plan.name = "Enterprise"
  plan.reason = "c-enterprise"
  plan.status = "active"
  plan.external_id = "b09c62e9e6954d0eb02a83110df03520"
  plan.frequency = 1
  plan.frequency_type = "months"
  plan.transaction_amount = 399.0
  plan.max_technicians = nil
  plan.max_orders = 300
  plan.support_level = "dedicado"
end

puts "Planos criados..."
puts "###################################"