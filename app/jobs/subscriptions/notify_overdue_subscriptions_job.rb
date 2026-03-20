class Subscriptions::NotifyOverdueSubscriptionsJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform
    subscription_ids = Subscription.overdue_for_notification.pluck(:id)

    if subscription_ids.any?
      notify_subscriptions(subscription_ids)
    else
      Rails.logger.info "[Subscriptions::NotifyOverdueSubscriptionsJob] Nenhuma assinatura vencida para notificar."
    end
  end

  private

  def notify_subscriptions(subscription_ids)
    subscription_ids.each do |id|
      result = Cmd::Subscriptions::NotifySubscription.new(subscription_id: id).call

      if result.success?
        Rails.logger.info "[Subscriptions::NotifyOverdueSubscriptionsJob] Notificacao de vencimento registrada para assinatura ID #{id}."
      else
        Rails.logger.error "[Subscriptions::NotifyOverdueSubscriptionsJob] Erro ao notificar assinatura ID #{id}: #{result.errors}"
      end
    rescue StandardError => e
      Rails.logger.error "[Subscriptions::NotifyOverdueSubscriptionsJob] Erro ao notificar assinatura ID #{id}: #{e.message}"
    end
  end
end
