module Queries
  module Reconciliation
    class PendingPixBoletoWithoutProcessedWebhookQuery
      def self.call(window_days: 30)
        days = normalize_days(window_days)
        sql = <<~SQL
          SELECT
            s.id AS subscription_id,
            s.company_id,
            c.payment_method,
            s.status,
            s.external_payment_id,
            s.updated_at
          FROM subscriptions s
          JOIN companies c ON c.id = s.company_id
          WHERE s.gateway = 'mercado_pago'
            AND s.status = 'pending'
            AND c.payment_method IN ('pix', 'boleto')
            AND s.external_payment_id IS NOT NULL
            AND s.external_payment_id <> ''
            AND s.updated_at >= NOW() - INTERVAL '#{days} days'
            AND NOT EXISTS (
              SELECT 1
              FROM webhook_events we
              WHERE we.provider = 'mercado_pago'
                AND we.event_type = 'payment'
                AND we.status = 'processed'
                AND we.resource_id = s.external_payment_id
            )
          ORDER BY s.updated_at DESC
        SQL

        ActiveRecord::Base.connection.exec_query(sql)
      end

      def self.normalize_days(window_days)
        days = window_days.to_i
        days.positive? ? days : 30
      end

      private_class_method :normalize_days
    end
  end
end
