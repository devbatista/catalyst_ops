module Webhooks
  class PaymentEventsStatusBreakdownQuery
    def self.call(window_days: 30)
      days = normalize_days(window_days)
      sql = <<~SQL
        SELECT
          we.status,
          COUNT(*) AS total
        FROM webhook_events we
        WHERE we.provider = 'mercado_pago'
          AND we.event_type = 'payment'
          AND we.created_at >= NOW() - INTERVAL '#{days} days'
        GROUP BY we.status
        ORDER BY total DESC
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
