require 'faker'

puts 'Criando os usuários'

USERS = []

# Admin
USERS << User.create!(
  name: "Admin",
  email: "admin@catalystops.local",
  password: "senha123",
  role: :admin,
  phone: Faker::PhoneNumber.cell_phone_in_e164,
  active: true
)

# Gestores e Técnicos
COMPANIES.each do |company|
  subscription = company.subscriptions.find_by(status: 'active')
  next if subscription.nil? || subscription.plan.nil? || !company.can_add_technician?
    
  max_tecs = subscription.plan.max_technicians || 10
  rand(1..max_tecs).times do
    USERS << User.create!(
      name: Faker::Name.name,
      email: Faker::Internet.unique.email,
      password: "senha123",
      role: :tecnico,
      company: company,
      phone: Faker::PhoneNumber.cell_phone_in_e164,
      active: true
    )
  end
end

puts 'Usuários criados'
puts '###################################'