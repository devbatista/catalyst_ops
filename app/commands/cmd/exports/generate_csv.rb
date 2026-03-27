module Cmd
  module Exports
    class GenerateCsv
      Result = Struct.new(:success?, :csv, :errors)

      TEMPLATES = {
        admin_logs: {
          headers: [
            "id",
            "occurred_at",
            "action",
            "source",
            "company_id",
            "company_name",
            "actor_type",
            "actor_id",
            "resource_type",
            "resource_id",
            "request_id",
            "ip_address",
            "user_agent",
            "metadata"
          ],
          row_builder: lambda do |log|
            [
              log.id,
              log.occurred_at&.iso8601,
              log.action,
              log.source,
              log.company_id,
              log.company&.name,
              log.actor_type,
              log.actor_id,
              log.resource_type,
              log.resource_id,
              log.request_id,
              log.ip_address,
              log.user_agent,
              log.metadata.to_json
            ]
          end
        }
      }.freeze

      def initialize(collection:, template: nil, headers: nil, batch_size: 1000, &row_builder)
        @collection = collection
        @template = template&.to_sym
        @headers = headers
        @batch_size = batch_size
        @row_builder = row_builder
      end

      def call
        if template.present? && resolved_template.blank?
          return Result.new(false, nil, "template nao suportado: #{template}")
        end

        resolved = resolved_template
        resolved_headers = resolved&.dig(:headers) || headers
        resolved_row_builder = resolved&.dig(:row_builder) || row_builder

        return Result.new(false, nil, "headers e obrigatorio") if resolved_headers.blank?
        return Result.new(false, nil, "row_builder e obrigatorio") unless resolved_row_builder

        csv = ::Exports::CsvBuilder.call(
          headers: resolved_headers,
          collection: collection,
          batch_size: batch_size
        ) do |record|
          resolved_row_builder.call(record)
        end

        Result.new(true, csv, nil)
      rescue StandardError => e
        Result.new(false, nil, e.message)
      end

      private

      attr_reader :headers, :collection, :batch_size, :row_builder, :template

      def resolved_template
        return nil if template.blank?

        TEMPLATES[template]
      end
    end
  end
end
