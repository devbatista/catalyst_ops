require "faker"

puts "Criando mensagens de suporte"

admin_user = USERS.find { |user| user.admin? }

SUPPORT_TICKETS.each do |ticket|
  participants = [ticket.user, admin_user].compact
  next if participants.empty?

  rand(1..3).times do |index|
    author = participants[index % participants.size]

    ticket.add_message!(
      user: author,
      body: Faker::Lorem.paragraph(sentence_count: 2)
    )
  end

  ticket.update!(
    status: [:aberto, :em_andamento, :aguardando_cliente, :resolvido].sample
  )
end

puts "Mensagens de suporte criadas"
puts "###################################"
