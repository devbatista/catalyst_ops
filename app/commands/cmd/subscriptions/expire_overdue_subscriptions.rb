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
          notify_expiration
          Result.new(true, @subscription, nil)
        rescue StandardError => e
          Result.new(false, @subscription, e.message)
        end
      end

      private

      def notify_expiration
        return if @subscription.expired_notification_sent_at.present?

        ::Subscriptions::ExpirationMailer.with(subscription: @subscription).expired_email.deliver_later
        @subscription.update!(expired_notification_sent_at: Time.current)
      end
    end
  end
end
