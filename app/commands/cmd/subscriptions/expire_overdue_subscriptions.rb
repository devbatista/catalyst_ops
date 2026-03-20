module Cmd
  module Subscriptions
    class ExpireOverdueSubscriptions
      Result = Struct.new(:success?, :subscription, :errors)

      def initialize(subscription_id:)
        @subscription = Subscription.find_by(id: subscription_id)
      end

      def call
        return Result.new(false, nil, "Assinatura não encontrada") unless @subscription
        return Result.new(true, @subscription, nil) if @subscription.expired?

        begin
          @subscription.transaction do
            @subscription.expire!
          end
          Result.new(true, @subscription, nil)
        rescue StandardError => e
          Result.new(false, @subscription, e.message)
        end
      end
    end
  end
end
