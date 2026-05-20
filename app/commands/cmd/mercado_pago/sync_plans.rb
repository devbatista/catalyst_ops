module Cmd
  module MercadoPago
    class SyncPlans
      def initialize(client: ::MercadoPago::Client.new)
        @client = client
      end

      def call
        plans_data = @client.fetch_plans
        delete_plans(plans_data)

        plans_data.each do |plan_data|
          plan = find_plan(plan_data)
          plan.update!(plan_params(plan_data))
        end
      end

      def delete_plans(plans_data = nil)
        plans_data ||= @client.fetch_plans
        fetched_ids = plans_data.map { |p| p["id"] }.compact

        Plan
          .where.not(external_id: fetched_ids)
          .where.not(id: Company.where.not(plan_id: nil).select(:plan_id))
          .where.not(external_id: Subscription.select(:preapproval_plan_id))
          .delete_all
      end

      private

      def find_plan(plan_data)
        Plan.find_by(external_id: plan_data["id"]) ||
          Plan.find_by(external_reference: plan_data["external_reference"]) ||
          Plan.new
      end

      def plan_params(plan_data)
        raw_reason = plan_data["reason"].to_s
        normalized_name = raw_reason.sub(/\Ac-/, "").capitalize

        auto_recurring = plan_data["auto_recurring"] || {}

        {
          name: normalized_name,
          reason: plan_data["reason"],
          status: plan_data["status"],
          external_id: plan_data["id"],
          external_reference: plan_data["external_reference"],
          frequency: auto_recurring["frequency"],
          frequency_type: auto_recurring["frequency_type"],
          transaction_amount: auto_recurring["transaction_amount"]
        }
      end
    end
  end
end
