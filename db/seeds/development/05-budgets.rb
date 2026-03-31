require "faker"

puts "Criando orçamentos"

BUDGETS = []

CLIENTS.each do |client|
  rand(4..8).times do
    budget = Budget.create!(
      title: Faker::Commerce.product_name,
      description: Faker::Lorem.sentence(word_count: 10),
      client: client,
      company: client.company,
      valid_until: Faker::Date.forward(days: 30)
    )

    rand(2..5).times do
      ServiceItem.create!(
        budget: budget,
        description: "#{Faker::Commerce.material} para #{Faker::Commerce.product_name}",
        quantity: rand(1..5),
        unit_price: Faker::Commerce.price(range: 50..500)
      )
    end

    # Recalcula total_value com base nos itens criados.
    budget.save!

    # Mantém uma variedade de estados sem criar OS neste seed.
    flow = [:rascunho, :enviado, :rejeitado].sample
    case flow
    when :enviado
      budget.send_for_approval!
    when :rejeitado
      budget.send_for_approval!
      budget.reject!(rejection_reason: "Cliente solicitou revisão de preço/prazo.")
    end

    BUDGETS << budget
  end
end

puts "Orçamentos criados: #{BUDGETS.size}"
puts "###################################"
