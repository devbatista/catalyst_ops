module Cmd
  module MercadoPago
    class CancelCreditCardSubscription
      Result = Struct.new(:success?, :payload, :errors)

      def initialize(subscription)
        @subscription = subscription
      end

      def call
        return Result.new(false, nil, "Assinatura não encontrada") if @subscription.blank?
        return Result.new(false, nil, "Assinatura sem external_subscription_id") if @subscription.external_subscription_id.blank?

        response =
          if Rails.env.production?
            ::MercadoPago::Client.new.request(
              method: :put,
              path: "/preapproval/#{@subscription.external_subscription_id}",
              body: { status: "cancelled" }
            )
          else
            {
              "id" => @subscription.external_subscription_id,
              "status" => "cancelled",
              "status_detail" => "cancelled_by_system"
            }
          end

        Result.new(true, response, nil)
      rescue StandardError => e
        Rails.logger.error("[Cmd::MercadoPago::CancelCreditCardSubscription] Falha ao cancelar assinatura #{@subscription&.id}: #{e.message}")
        Result.new(false, nil, e.message)
      end
    end
  end
end
