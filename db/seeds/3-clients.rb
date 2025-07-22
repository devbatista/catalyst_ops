require 'faker'
require 'cpf_cnpj'

puts 'Criando clientes'

CLIENTS = []

COMPANIES.each do |company|
  rand(3..10).times do
    CLIENTS << Client.create!(
      name: Faker::Name.name,
      document: [CPF.generate, CNPJ.generate].sample,
      email: Faker::Internet.unique.email,
      phone: Faker::PhoneNumber.cell_phone.gsub(/\D/, '')[0, 11],
      address: Faker::Address.full_address,
      company: company
    )
  end
end

puts 'Clientes criados'
puts '###################################'