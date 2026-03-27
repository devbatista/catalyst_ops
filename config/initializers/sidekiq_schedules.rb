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
      "NotifyOverdueSubscriptionsJob" => {
        "cron" => "0 9 * * *", # Diariamente às 09h00
        "class" => "Subscriptions::NotifyOverdueSubscriptionsJob",
        "queue" => "default",
        "description" => "Notifica clientes com assinaturas vencidas há 5 dias",
        "timezone" => "America/Sao_Paulo"
      },
      "ExpireOverdueSubscriptionsJob" => {
        "cron" => "0 11 * * *", # Diariamente às 11h00
        "class" => "Subscriptions::ExpireOverdueSubscriptionsJob",
        "queue" => "default",
        "description" => "Expira assinaturas vencidas há 10 dias ou mais",
        "timezone" => "America/Sao_Paulo"
      },
      "ReconcileSubscriptionsJob" => {
        "cron" => "0 12 * * *", # Diariamente às 12h00
        "class" => "Subscriptions::ReconcileSubscriptionsJob",
        "queue" => "default",
        "description" => "Reconcilia status local de assinaturas com o gateway Mercado Pago",
        "timezone" => "America/Sao_Paulo"
      },
      "ReprocessPendingPaymentsJob" => {
        "cron" => "30 12 * * *", # Diariamente às 12h30
        "class" => "Subscriptions::ReprocessPendingPaymentsJob",
        "queue" => "default",
        "description" => "Reprocessa assinaturas pending (pix/boleto) sem webhook de payment processado",
        "timezone" => "America/Sao_Paulo"
      },
      "AuditCleanupEventsJob" => {
        "cron" => "0 2 * * *", # Diariamente às 02h00
        "class" => "Audit::CleanupEventsJob",
        "queue" => "default",
        "description" => "Remove audit_events antigos conforme politica de retencao",
        "timezone" => "America/Sao_Paulo"
      }
    }

    Sidekiq::Cron::Job.load_from_hash!(schedules_hash)
  end
end
