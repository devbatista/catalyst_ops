module Queries
  module Webhooks
    class PossibleDuplicatePaymentEventsQuery
      def self.call
        sql = <<~SQL
          SELECT
            we.resource_id,
            COUNT(*) AS total_events,
            MIN(we.created_at) AS first_seen_at,
            MAX(we.created_at) AS last_seen_at
          FROM webhook_events we
          WHERE we.provider = 'mercado_pago'
            AND we.event_type = 'payment'
            AND we.resource_id IS NOT NULL
            AND we.resource_id <> ''
          GROUP BY we.resource_id
          HAVING COUNT(*) > 1
          ORDER BY total_events DESC, last_seen_at DESC
        SQL

        ActiveRecord::Base.connection.exec_query(sql)
      end
    end
  end
end
