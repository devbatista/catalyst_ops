Sidekiq.configure_server do |config|
  config.on(:startup) do
    schedules_hash = {
      "MarkOverdueOrderServicesJob" => {
        "cron" => "* * * * *", # A cada minuto
        "class" => "MarkOverdueOrderServicesJob",
        "queue" => "default",
        "description" => "Marca OS como atrasadas se a data de agendamento já passou",
        "timezone" => "America/Sao_Paulo"
      },
      "CycleSubscriptionsJob" => {
        "cron" => "0 10 * * *", # Diariamente às 10h00
        "class" => "Subscriptions::CycleSubscriptionsJob",
        "queue" => "default",
        "description" => "Cicla as assinaturas das empresas",
        "timezone" => "America/Sao_Paulo"
      },
      "ExpireSubscriptionsJob" => {
        "cron" => "0 11 * * *", # Diariamente às 11h00
        "class" => "Subscriptions::ExpireSubscriptionsJob",
        "queue" => "default",
        "description" => "Expira assinaturas vencidas",
        "timezone" => "America/Sao_Paulo"
      }
    }

    Sidekiq::Cron::Job.load_from_hash!(schedules_hash)
  end
end