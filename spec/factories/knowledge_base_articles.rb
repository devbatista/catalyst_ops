FactoryBot.define do
  factory :knowledge_base_article do
    title { "Como acompanhar uma ordem de serviço" }
    content { "Abra a ordem de serviço e acompanhe o histórico de atendimentos." }
    category { "Atendimento" }
    audience { "gestor" }
    sequence(:slug) { |n| "artigo-base-conhecimento-#{n}" }
  end
end
