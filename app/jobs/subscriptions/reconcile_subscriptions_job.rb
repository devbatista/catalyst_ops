class Subscriptions::ReconcileSubscriptionsJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform
    subscription_ids = subscriptions_to_reconcile.pluck(:id)

    if subscription_ids.any?
      reconcile_subscriptions(subscription_ids)
      Rails.logger.info "[Subscriptions::ReconcileSubscriptionsJob] #{subscription_ids.size} assinatura(s) processada(s) na reconciliacao."
    else
      Rails.logger.info "[Subscriptions::ReconcileSubscriptionsJob] Nenhuma assinatura elegivel para reconciliacao."
    end
  end

  private

  def subscriptions_to_reconcile
    base = Subscription.where(gateway: "mercado_pago", status: %w[pending active])

    credit_card_scope = base
      .joins(:company)
      .where(companies: { payment_method: "credit_card" })
      .where.not(external_subscription_id: [nil, ""])

    pix_boleto_scope = base
      .joins(:company)
      .where(companies: { payment_method: %w[pix boleto] })
      .where.not(external_payment_id: [nil, ""])

    credit_card_scope.or(pix_boleto_scope).recent
  end

  def reconcile_subscriptions(subscription_ids)
    subscription_ids.each do |id|
      result = Cmd::Subscriptions::ReconcileSubscription.new(subscription_id: id).call

      if result.success?
        Rails.logger.info "[Subscriptions::ReconcileSubscriptionsJob] Assinatura ID #{id} reconciliada com sucesso."
      else
        Rails.logger.error "[Subscriptions::ReconcileSubscriptionsJob] Falha ao reconciliar assinatura ID #{id}: #{result.errors}"
      end
    rescue StandardError => e
      Rails.logger.error "[Subscriptions::ReconcileSubscriptionsJob] Erro ao reconciliar assinatura ID #{id}: #{e.message}"
    end
  end
end
