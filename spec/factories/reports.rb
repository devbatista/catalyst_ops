FactoryBot.define do
  factory :report do
    title { "Relatório de Clientes" }
    report_type { :clients }
    status { :pending }
    user { association(:user, :gestor, company: company, active: true) }
    company
    filters { { "q" => "cliente" } }
  end
end
