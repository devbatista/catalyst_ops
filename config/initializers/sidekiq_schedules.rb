Sidekiq.configure_server do |config|
  config.on(:startup) do
    schedules = [
      {
        name: "TestJob",
        cron: "* * * * *",           # a cada minuto
        class: "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper",
        queue: "default",
        description: "Testa a execução do Sidekiq Cron a cada minuto",
        args: [
          { 
            job_class: "TestJob",
            job_id: SecureRandom.uuid,
            queue_name: "default",
            arguments: []
          }
        ]
      }
    ]

    Sidekiq::Cron::Job.load_from_array(schedules)
  end
end