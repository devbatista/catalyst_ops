FactoryBot.define do
  factory :support_message do
    support_ticket
    user { association(:user, :gestor, company: support_ticket.company, active: true) }
    body { "Mensagem enviada ao suporte." }
  end
end
