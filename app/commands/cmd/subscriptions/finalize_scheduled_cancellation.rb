module Cmd
  module Subscriptions
    class FinalizeScheduledCancellation
      Result = Struct.new(:success?, :subscription, :errors)

      def initialize(subscription_id:)
        @subscription = Subscription.find_by(id: subscription_id)
      end

      def call
        return Result.new(false, nil, "Assinatura não encontrada") unless @subscription

        unless @subscription.cancel_due?
          return Result.new(false, @subscription, "Assinatura ainda não está no período de cancelamento efetivo")
        end

        begin
          cancel_gateway_subscription_if_needed!

          @subscription.transaction do
            @subscription.finalize_scheduled_cancellation!
          end

          Subscriptions::CancellationMailer.with(subscription: @subscription).cancelled_email.deliver_later

          Result.new(true, @subscription, nil)
        rescue StandardError => e
          Result.new(false, @subscription, e.message)
        end
      end

      def cancel_gateway_subscription_if_needed!
        return unless @subscription.company&.payment_method == "credit_card"
        return if @subscription.external_subscription_id.blank?

        result = Cmd::MercadoPago::CancelCreditCardSubscription.new(@subscription).call
        raise "Falha ao cancelar assinatura no gateway: #{result.errors}" unless result.success?
      end
    end
  end
end
