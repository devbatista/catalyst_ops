class Subscriptions::ReprocessPendingPaymentsJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform
    subscription_ids = pending_subscription_ids_without_processed_webhook

    if subscription_ids.any?
      reprocess_subscriptions(subscription_ids)
      Rails.logger.info "[Subscriptions::ReprocessPendingPaymentsJob] #{subscription_ids.size} assinatura(s) pending reprocessada(s) (janela: #{reprocess_window_days} dias)."
    else
      Rails.logger.info "[Subscriptions::ReprocessPendingPaymentsJob] Nenhuma assinatura pending sem webhook para reprocessar (janela: #{reprocess_window_days} dias)."
    end
  end

  private

  def reprocess_window_days
    raw_value = ENV.fetch("SUBSCRIPTIONS_PENDING_REPROCESS_WINDOW_DAYS", 30)
    days = raw_value.to_i
    days.positive? ? days : 30
  end

  def pending_subscription_ids_without_processed_webhook
    result = Cmd::Queries::RunOperationalQuery.new(
      query_name: :pending_pix_boleto_without_processed_webhook,
      params: { window_days: reprocess_window_days }
    ).call

    unless result.success?
      Rails.logger.error "[Subscriptions::ReprocessPendingPaymentsJob] Falha ao carregar query operacional: #{result.errors}"
      return []
    end

    result.rows.map { |row| row["subscription_id"] }.compact
  end

  def reprocess_subscriptions(subscription_ids)
    subscription_ids.each do |id|
      result = Cmd::Subscriptions::ReconcileSubscription.new(subscription_id: id).call

      if result.success?
        Rails.logger.info "[Subscriptions::ReprocessPendingPaymentsJob] Assinatura ID #{id} reprocessada com sucesso."
      else
        Rails.logger.error "[Subscriptions::ReprocessPendingPaymentsJob] Falha ao reprocessar assinatura ID #{id}: #{result.errors}"
      end
    rescue StandardError => e
      Rails.logger.error "[Subscriptions::ReprocessPendingPaymentsJob] Erro ao reprocessar assinatura ID #{id}: #{e.message}"
    end
  end
end
