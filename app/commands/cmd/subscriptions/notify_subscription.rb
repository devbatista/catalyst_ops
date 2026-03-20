module Cmd
  module Subscriptions
    class NotifySubscription
      Result = Struct.new(:success?, :subscription, :errors)

      def initialize(subscription_id:)
        @subscription = Subscription.includes(:company, :plan).find_by(id: subscription_id)
      end

      def call
        return Result.new(false, nil, "Assinatura não encontrada") unless @subscription
        return Result.new(false, @subscription, "Assinatura já notificada") if @subscription.expiration_warning_sent_at.present?

        begin
          @subscription.transaction do
            Subscriptions::ExpirationWarningMailer
              .with(subscription: @subscription)
              .warning_email
              .deliver_later

            @subscription.update!(expiration_warning_sent_at: Time.current)
          end

          Result.new(true, @subscription, nil)
        rescue StandardError => e
          Result.new(false, @subscription, e.message)
        end
      end
    end
  end
end
