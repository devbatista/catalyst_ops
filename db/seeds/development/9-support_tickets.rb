require "faker"

puts "Criando tickets de suporte"

SUPPORT_TICKETS = []
admin_user = USERS.find { |user| user.admin? }

COMPANIES.each do |company|
  gestor = company.users.find_by(role: :gestor)
  next unless gestor

  company_order_services = ORDER_SERVICES.select { |order_service| order_service.company_id == company.id }

  rand(2..4).times do
    order_service = company_order_services.sample

    ticket = SupportTicket.create!(
      company: company,
      user: gestor,
      order_service: [order_service, nil].sample,
      subject: [
        "Dúvida sobre fechamento da OS",
        "Problema ao anexar arquivos",
        "Pedido de ajuste no painel",
        "Erro no cadastro de atendimento"
      ].sample,
      description: Faker::Lorem.paragraph(sentence_count: 2),
      category: SupportTicket.categories.keys.sample,
      impact: SupportTicket.impacts.keys.sample,
      priority: SupportTicket.priorities.keys.sample,
      status: :aberto
    )

    if admin_user && [true, false].sample
      ticket.add_message!(
        user: admin_user,
        body: "Recebemos seu ticket e estamos analisando o caso."
      )
    end

    SUPPORT_TICKETS << ticket
  end
end

puts "Tickets de suporte criados"
puts "###################################"
