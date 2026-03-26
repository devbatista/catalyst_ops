class Subscriptions::ReconcileSubscriptionsJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform
    subscription_ids = subscriptions_to_reconcile.pluck(:id)

    if subscription_ids.any?
      reconcile_subscriptions(subscription_ids)
      Rails.logger.info "[Subscriptions::ReconcileSubscriptionsJob] #{subscription_ids.size} assinatura(s) processada(s) na reconciliacao (janela: #{reconciliation_window_days} dias)."
    else
      Rails.logger.info "[Subscriptions::ReconcileSubscriptionsJob] Nenhuma assinatura elegivel para reconciliacao (janela: #{reconciliation_window_days} dias)."
    end
  end

  private

  def subscriptions_to_reconcile
    base = Subscription
      .where(gateway: "mercado_pago", status: %w[pending active])
      .where("subscriptions.updated_at >= ?", reconciliation_window_start)

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

  def reconciliation_window_days
    raw_value = ENV.fetch("SUBSCRIPTIONS_RECONCILIATION_WINDOW_DAYS", 30)
    days = raw_value.to_i
    days.positive? ? days : 30
  end

  def reconciliation_window_start
    reconciliation_window_days.days.ago
  end

  def reconcile_subscriptions(subscription_ids)
    subscription_ids.each do |id|
      result = Cmd::Subscriptions::ReconcileSubscription.new(
        subscription_id: id,
        source_job: self.class.name,
        window_days: reconciliation_window_days
      ).call

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
