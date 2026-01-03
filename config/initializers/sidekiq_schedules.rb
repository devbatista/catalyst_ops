Sidekiq.configure_server do |config|
  config.on(:startup) do
    schedules_hash = {
      "MarkOverdueOrderServicesJob" => {
        "cron" => "* * * * *", # A cada minuto
        "class" => "MarkOverdueOrderServicesJob",
        "queue" => "default",
        "description" => "Marca OS como atrasadas se a data de agendamento já passou"
      },
      "CycleSubscriptionsJob" => {
        "cron" => "0 10 * * *", # Diariamente às 10h00
        "class" => "Subscriptions::CycleSubscriptionsJob",
        "queue" => "default",
        "description" => "Cicla as assinaturas das empresas"
      }
    }

    Sidekiq::Cron::Job.load_from_hash!(schedules_hash)
  end
end