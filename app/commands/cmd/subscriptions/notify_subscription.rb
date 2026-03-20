module Cmd
  module Subscriptions
    class NotifySubscription
      Result = Struct.new(:success?, :subscription, :errors)

      def initialize(subscription_id:)
        @subscription = Subscription.includes(:company, :plan).find_by(id: subscription_id)
      end

      def call
        return Result.new(false, nil, "Assinatura não encontrada") unless @subscription

        begin
          Subscriptions::ExpirationWarningMailer
            .with(subscription: @subscription)
            .warning_email
            .deliver_later

          Result.new(true, @subscription, nil)
        rescue StandardError => e
          Result.new(false, @subscription, e.message)
        end
      end
    end
  end
end
