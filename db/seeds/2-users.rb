require 'faker'

puts 'Criando os usuários'

USERS = []

# Admin
USERS << User.create!(
  name: "Admin",
  email: "admin@catalystops.dev",
  password: "senha123",
  role: :admin,
  phone: Faker::PhoneNumber.cell_phone_in_e164,
  active: true
)

# Gestores e Técnicos
COMPANIES.each do |company|
  rand(1..3).times do
    USERS << User.create!(
      name: Faker::Name.name,
      email: Faker::Internet.unique.email,
      password: "senha123",
      role: :gestor,
      company: company,
      phone: Faker::PhoneNumber.cell_phone_in_e164
      active: true
    )
  end
  rand(1..5).times do
    USERS << User.create!(
      name: Faker::Name.name,
      email: Faker::Internet.unique.email,
      password: "senha123",
      role: :tecnico,
      company: company,
      phone: Faker::PhoneNumber.cell_phone_in_e164,
      active: [true, false].sample
    )
  end
end

puts 'Usuários criados'
puts '###################################'