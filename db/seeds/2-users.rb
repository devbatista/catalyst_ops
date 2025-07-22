require 'faker'

puts 'Criando os usuários'

USERS = []

# Admin
USERS << User.create!(
  name: "Admin",
  email: "admin@catalystops.dev",
  password: "senha123",
  role: :admin
)

# Gestores e Técnicos
COMPANIES.each do |company|
  rand(1..3).times do
    USERS << User.create!(
      name: Faker::Name.name,
      email: Faker::Internet.unique.email,
      password: "senha123",
      role: :gestor,
      company: company
    )
  end
  rand(1..5).times do
    USERS << User.create!(
      name: Faker::Name.name,
      email: Faker::Internet.unique.email,
      password: "senha123",
      role: :tecnico,
      company: company
    )
  end
end

puts 'Usuários criados'
puts '###################################'