module Cmd
  module Subscriptions
    class ReconcileSubscription
      Result = Struct.new(:success?, :subscription, :errors)

      def initialize(subscription_id:)
        @subscription = Subscription.find_by(id: subscription_id)
      end

      def call
        return Result.new(false, nil, "Assinatura nao encontrada") if @subscription.blank?

        case @subscription.company&.payment_method
        when "credit_card"
          return Result.new(false, @subscription, "Assinatura de cartao sem preapproval_id para reconciliacao") if @subscription.external_subscription_id.blank?
          reconcile_by_preapproval
        when "pix", "boleto"
          return Result.new(false, @subscription, "Assinatura sem payment_id para reconciliacao") if @subscription.external_payment_id.blank?
          reconcile_by_payment
        else
          Result.new(false, @subscription, "Metodo de pagamento #{@subscription.company&.payment_method.inspect} nao suportado na reconciliacao")
        end
      rescue StandardError => e
        Result.new(false, @subscription, e.message)
      end

      private

      def reconcile_by_payment
        payment = MercadoPago::Subscriptions.fetch_payment(@subscription.external_payment_id)
        return Result.new(false, @subscription, "Pagamento #{@subscription.external_payment_id} nao encontrado no gateway") if payment.blank?

        @subscription.with_lock do
          @subscription.update!(
            external_payment_id: payment["id"].to_s.presence || @subscription.external_payment_id,
            raw_payload: payment
          )

          apply_gateway_status(payment["status"], approved_at: parse_time(payment["date_approved"]))
        end

        Result.new(true, @subscription, nil)
      end

      def reconcile_by_preapproval
        preapproval = MercadoPago::Subscriptions.fetch_preapproval(@subscription.external_subscription_id)
        return Result.new(false, @subscription, "Preapproval #{@subscription.external_subscription_id} nao encontrado no gateway") if preapproval.blank?

        @subscription.with_lock do
          @subscription.update!(
            external_reference: @subscription.external_reference.presence || preapproval["external_reference"],
            raw_payload: preapproval
          )

          apply_gateway_status(preapproval["status"])
        end

        Result.new(true, @subscription, nil)
      end

      def apply_gateway_status(status, approved_at: nil)
        normalized = status.to_s.downcase

        case normalized
        when "approved", "authorized"
          activate_subscription(approved_at || Time.current)
        when "cancelled", "canceled", "paused", "rejected"
          @subscription.cancel! unless @subscription.cancelled?
        when "pending", "in_process"
          @subscription.update!(status: :pending) unless @subscription.pending? || @subscription.active?
        end
      end

      def activate_subscription(started_at)
        return if @subscription.active?

        @subscription.activate_for!(started_at: started_at)
      end

      def parse_time(value)
        return if value.blank?

        Time.zone.parse(value)
      rescue ArgumentError
        nil
      end
    end
  end
end
