FactoryBot.define do
  factory :support_ticket do
    company
    user { association(:user, :gestor, company: company, active: true) }
    subject { "Problema ao emitir orçamento" }
    description { "Não consigo finalizar o orçamento pelo painel." }
    category { :problema_tecnico }
    impact { :medio }
    status { :aberto }
    priority { :normal }
  end
end
