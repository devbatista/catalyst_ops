class Subscriptions::ExpireOverdueSubscriptionsJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform
    subscriptions = Subscription.overdue_for_expiration
    subscription_ids = subscriptions.pluck(:id)

    if subscription_ids.any?
      expire_subscriptions(subscription_ids)
      Rails.logger.info "[Subscriptions::ExpireOverdueSubscriptionsJob] #{subscription_ids.size} assinatura(s) processada(s) para expiracao."
    else
      Rails.logger.info "[Subscriptions::ExpireOverdueSubscriptionsJob] Nenhuma assinatura vencida ha 10 dias ou mais para expirar."
    end
  end

  private

  def expire_subscriptions(subscription_ids)
    subscription_ids.each do |id|
      result = Cmd::Subscriptions::ExpireOverdueSubscriptions.new(subscription_id: id).call

      if result.success?
        Rails.logger.info "[Subscriptions::ExpireOverdueSubscriptionsJob] Assinatura ID #{id} expirada com sucesso."
      else
        Rails.logger.error "[Subscriptions::ExpireOverdueSubscriptionsJob] Falha ao expirar assinatura ID #{id}: #{result.errors}"
      end
    rescue StandardError => e
      Rails.logger.error "[Subscriptions::ExpireOverdueSubscriptionsJob] Erro ao expirar assinatura ID #{id}: #{e.message}"
    end
  end
end
