module Cmd
  module Queries
    class RunOperationalQuery
      Result = Struct.new(:success?, :rows, :columns, :errors)

      QUERY_MAP = {
        pending_pix_boleto_without_processed_webhook: lambda { |params|
          ::Queries::Reconciliation::PendingPixBoletoWithoutProcessedWebhookQuery.call(
            window_days: params.fetch(:window_days, 30)
          )
        },
        reconciliation_window_summary: lambda { |params|
          ::Queries::Reconciliation::ReconciliationWindowSummaryQuery.call(
            window_days: params.fetch(:window_days, 30)
          )
        },
        payment_events_status_breakdown: lambda { |params|
          ::Queries::Webhooks::PaymentEventsStatusBreakdownQuery.call(
            window_days: params.fetch(:window_days, 30)
          )
        },
        possible_duplicate_payment_events: lambda { |_params|
          ::Queries::Webhooks::PossibleDuplicatePaymentEventsQuery.call
        }
      }.freeze

      def initialize(query_name:, params: {})
        @query_name = query_name.to_sym
        @params = params.to_h.symbolize_keys
      end

      def call
        query_runner = QUERY_MAP[@query_name]
        return Result.new(false, [], [], "Query nao suportada: #{@query_name}") if query_runner.blank?

        result = query_runner.call(@params)
        Result.new(true, result.to_a, result.columns, nil)
      rescue StandardError => e
        Result.new(false, [], [], e.message)
      end

      def self.available_queries
        QUERY_MAP.keys
      end
    end
  end
end
