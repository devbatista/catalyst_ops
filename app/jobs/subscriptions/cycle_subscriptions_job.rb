
class Subscriptions::CycleSubscriptionsJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform
    subscription_ids = Subscription.ready_to_cycle.pluck(:id)

    if subscription_ids.any?
      cycle_subscriptions(subscription_ids)
    else
      Rails.logger.info "[Subscriptions::CycleSubscriptionsJob] Nenhuma assinatura para renovar."
    end
  end

  private

  def cycle_subscriptions(subscription_ids)
    subscription_ids.each do |id|
      Cmd::Subscriptions::CycleSubscription.new(subscription_id: id).call
      Rails.logger.info "[Subscriptions::CycleSubscriptionsJob] Assinatura ID #{id} ciclada com sucesso."
    rescue StandardError => e
      Rails.logger.error "[Subscriptions::CycleSubscriptionsJob] Erro ao ciclar assinatura ID #{id}: #{e.message}"
    end
  end
end