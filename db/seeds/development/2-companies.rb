require 'faker'
require 'cpf_cnpj'

puts 'Criando as empresas'

PLANS = Plan.all.to_a

COMPANIES = Array.new(rand(3..10)) do
  plan = PLANS.sample
  company = Company.create!(
    name: Faker::Company.name,
    document: [CPF.generate, CNPJ.generate].sample,
    email: Faker::Internet.unique.email,
    phone: Faker::PhoneNumber.cell_phone.gsub(/\D/, '')[0, 11],
    state_registration: Faker::Number.number(digits: 9),
    municipal_registration: Faker::Number.number(digits: 9),
    plan: plan,
    number: Faker::Address.building_number,
    complement: Faker::Address.secondary_address,
    neighborhood: Faker::Address.community,
    city: Faker::Address.city,
    state: Faker::Address.state_abbr,
    zip_code: Faker::Address.zip_code.delete('-'),
    street: Faker::Address.street_name,
    active: true
  )

  gestor = User.create!(
    name: Faker::Name.name,
    email: Faker::Internet.unique.email,
    password: "senha123",
    role: :gestor,
    company: company,
    phone: Faker::PhoneNumber.cell_phone_in_e164,
    active: true,
    can_be_technician: [true, false].sample
  )
  company.update!(responsible_id: gestor.id)

  company.subscriptions.create!(
    preapproval_plan_id: plan.external_id,
    status: :active, 
    start_date: Time.current,
    end_date: 1.month.from_now
  )

  company
end

puts 'Empresas criadas...'
puts '###################################'