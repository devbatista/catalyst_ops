require 'faker'
require 'cpf_cnpj'

puts 'Criando clientes'

CLIENTS = []

COMPANIES.each do |company|
  rand(3..10).times do
    client = Client.create!(
      name: Faker::Name.name,
      document: [CPF.generate, CNPJ.generate].sample,
      email: Faker::Internet.unique.email,
      phone: Faker::PhoneNumber.cell_phone.gsub(/\D/, '')[0, 11],
      company: company
    )
    client.addresses.create!(
      street: Faker::Address.street_name,
      number: rand(1..999).to_s,
      complement: Faker::Address.secondary_address,
      neighborhood: Faker::Address.community,
      zip_code: "#{rand(10000..99999)}-#{rand(100..999)}",
      city: Faker::Address.city,
      state: Faker::Address.state_abbr,
      country: "Brasil",
      address_type: "principal"
    )
    CLIENTS << client
  end
end

puts 'Clientes criados'
puts '###################################'