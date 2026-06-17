class Subscriptions::FinalizeScheduledCancellationsJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform
    started_at = Time.current
    job_audit.started(event: "scheduled_cancellations_started")

    subscription_ids = Subscription.scheduled_for_cancellation_due.pluck(:id)
    processed_count = 0
    success_count = 0
    error_count = 0

    if subscription_ids.any?
      processed_count, success_count, error_count = finalize_subscriptions(subscription_ids)
      Rails.logger.info "[Subscriptions::FinalizeScheduledCancellationsJob] #{subscription_ids.size} assinatura(s) cancelada(s) no fim do período."
    else
      Rails.logger.info "[Subscriptions::FinalizeScheduledCancellationsJob] Nenhuma assinatura agendada para cancelamento hoje."
    end

    job_audit.completed(
      event: "scheduled_cancellations_completed",
      started_at: started_at,
      extra: {
        subscriptions_found: subscription_ids.size,
        subscriptions_processed: processed_count,
        subscriptions_success: success_count,
        subscriptions_error: error_count
      }
    )
  rescue StandardError => e
    job_audit.failed(
      event: "scheduled_cancellations_failed",
      error: e
    )
    raise
  end

  private

  def finalize_subscriptions(subscription_ids)
    processed_count = 0
    success_count = 0
    error_count = 0

    subscription_ids.each do |id|
      result = Cmd::Subscriptions::FinalizeScheduledCancellation.new(subscription_id: id).call
      processed_count += 1

      if result.success?
        success_count += 1
        Rails.logger.info "[Subscriptions::FinalizeScheduledCancellationsJob] Assinatura ID #{id} cancelada com sucesso."
      else
        error_count += 1
        Rails.logger.error "[Subscriptions::FinalizeScheduledCancellationsJob] Falha ao cancelar assinatura ID #{id}: #{result.errors}"
      end
    rescue StandardError => e
      processed_count += 1
      error_count += 1
      Rails.logger.error "[Subscriptions::FinalizeScheduledCancellationsJob] Erro ao cancelar assinatura ID #{id}: #{e.message}"
    end

    [processed_count, success_count, error_count]
  end

  def job_audit
    @job_audit ||= Audit::JobLifecycleLogger.new(
      job_name: self.class.name,
      jid: jid
    )
  end
end
