Sidekiq.configure_server do |config|
  config.on(:startup) do
    schedules_hash = {
      "MarkOverdueOrderServicesJob" => {
        "cron"        => "* * * * *",
        "class"       => "MarkOverdueOrderServicesJob",
        "queue"       => "default",
        "description" => "Marca OS como atrasadas se a data de agendamento já passou"
      }
    }

    Sidekiq::Cron::Job.load_from_hash!(schedules_hash)
  end
end