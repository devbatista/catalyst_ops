class Subscriptions::FinalizeScheduledCancellationsJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform
    subscription_ids = Subscription.scheduled_for_cancellation_due.pluck(:id)

    if subscription_ids.any?
      finalize_subscriptions(subscription_ids)
      Rails.logger.info "[Subscriptions::FinalizeScheduledCancellationsJob] #{subscription_ids.size} assinatura(s) cancelada(s) no fim do período."
    else
      Rails.logger.info "[Subscriptions::FinalizeScheduledCancellationsJob] Nenhuma assinatura agendada para cancelamento hoje."
    end
  end

  private

  def finalize_subscriptions(subscription_ids)
    subscription_ids.each do |id|
      result = Cmd::Subscriptions::FinalizeScheduledCancellation.new(subscription_id: id).call

      if result.success?
        Rails.logger.info "[Subscriptions::FinalizeScheduledCancellationsJob] Assinatura ID #{id} cancelada com sucesso."
      else
        Rails.logger.error "[Subscriptions::FinalizeScheduledCancellationsJob] Falha ao cancelar assinatura ID #{id}: #{result.errors}"
      end
    rescue StandardError => e
      Rails.logger.error "[Subscriptions::FinalizeScheduledCancellationsJob] Erro ao cancelar assinatura ID #{id}: #{e.message}"
    end
  end
end
