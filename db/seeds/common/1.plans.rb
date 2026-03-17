puts "Criando os planos..."

Plan.find_or_create_by!(external_reference: "BASICO") do |plan|
  plan.name = "Basico"
  plan.reason = "c-basico"
  plan.status = "active"
  plan.external_id = "e38f93dc444940c7b0f326c734752883"
  plan.frequency = 1
  plan.frequency_type = "months"
  plan.transaction_amount = 99.0
  plan.max_technicians = 1
  plan.max_orders = 15
  plan.support_level = "email"
end

Plan.find_or_create_by!(external_reference: "PROFISSIONAL") do |plan|
  plan.name = "Profissional"
  plan.reason = "c-profissional"
  plan.status = "active"
  plan.external_id = "0dd58b3ca8b349b892ec9bdc151c9747"
  plan.frequency = 1
  plan.frequency_type = "months"
  plan.transaction_amount = 199.0
  plan.max_technicians = 6
  plan.max_orders = 60
  plan.support_level = "prioritario"
end

Plan.find_or_create_by!(external_reference: "ENTERPRISE") do |plan|
  plan.name = "Enterprise"
  plan.reason = "c-enterprise"
  plan.status = "active"
  plan.external_id = "42eee0e64dfb4ff5a52e710da6e86fdc"
  plan.frequency = 1
  plan.frequency_type = "months"
  plan.transaction_amount = 399.0
  plan.max_technicians = nil
  plan.max_orders = 200
  plan.support_level = "dedicado"
end

puts "Planos criados..."
puts "###################################"