class Subscriptions::ExpireSubscriptionsJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform
    subscription_ids = Subscriptions.where(end_date: Date.today - 1).pluck(:id)

    if subscription_ids.any?
      expire_subscriptions(subscription_ids)
    else
      Rails.logger.info "[Subscriptions::ExpireSubscriptionsJob] Nenhuma assinatura para expirar."
    end
  end

  private

  def expire_subscriptions(subscription_ids)
    subscription_ids.each do |id|
      result = Cmd::Subscriptions::ExpireSubscription.new(subscription_id: id).call

      if result.success?
        Rails.logger.info "[Subscriptions::ExpireSubscriptionsJob] Assinatura ID #{id} expirada com sucesso."
      else
        Rails.logger.error "[Subscriptions::ExpireSubscriptionsJob] Erro ao expirar assinatura ID #{id}: #{result.errors}"
      end
    rescue StandardError => e
      Rails.logger.error "[Subscriptions::ExpireSubscriptionsJob] Erro ao expirar assinatura ID #{id}: #{e.message}"
    end
  end
end