require 'faker'
require 'cpf_cnpj'

puts 'Criando as empresas'

COMPANIES = Array.new(rand(3..10)) do
  Company.create!(
    name: Faker::Company.name,
    document: [CPF.generate, CNPJ.generate].sample,
    email: Faker::Internet.unique.email,
    phone: Faker::PhoneNumber.cell_phone.gsub(/\D/, '')[0, 11],
    address: Faker::Address.full_address,
    state_registration: Faker::Number.number(digits: 9),
    municipal_registration: Faker::Number.number(digits: 9)
  )
end

puts 'Empresas criadas...'
puts '###################################'