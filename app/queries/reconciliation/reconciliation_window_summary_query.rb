module Queries
  module Reconciliation
    class ReconciliationWindowSummaryQuery
      def self.call(window_days: 30)
        days = normalize_days(window_days)
        sql = <<~SQL
          SELECT
            COUNT(*) AS total,
            SUM(CASE WHEN s.status = 'pending' THEN 1 ELSE 0 END) AS pending_count,
            SUM(CASE WHEN s.status = 'active' THEN 1 ELSE 0 END) AS active_count,
            SUM(CASE WHEN c.payment_method = 'credit_card' THEN 1 ELSE 0 END) AS credit_card_count,
            SUM(CASE WHEN c.payment_method IN ('pix', 'boleto') THEN 1 ELSE 0 END) AS pix_boleto_count
          FROM subscriptions s
          JOIN companies c ON c.id = s.company_id
          WHERE s.gateway = 'mercado_pago'
            AND s.status IN ('pending', 'active')
            AND s.updated_at >= NOW() - INTERVAL '#{days} days'
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
