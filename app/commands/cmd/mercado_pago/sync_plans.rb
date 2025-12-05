module Cmd
  module MercadoPago
    class SyncPlans
      def initialize(client: ::MercadoPago::Client.new)
        @client = client
      end

      def call
        plans_data = @client.fetch_plans # deve retornar array de hashes do MP

        plans_data.each do |plan_data|
          auto_recurring = plan_data["auto_recurring"] || {}

          raw_reason = plan_data["reason"].to_s
          normalized_name = raw_reason.sub(/\Ac-/, "").capitalize

          plan = Plan.find_or_initialize_by(external_id: plan_data["id"])
          plan.name = normalized_name
          plan.reason = plan_data["reason"]
          plan.status = plan_data["status"]
          plan.external_reference = plan_data["external_reference"]

          plan.frequency = auto_recurring["frequency"]
          plan.frequency_type = auto_recurring["frequency_type"]
          plan.transaction_amount = auto_recurring["transaction_amount"]

          plan.save!
        end
      end
    end
  end
end