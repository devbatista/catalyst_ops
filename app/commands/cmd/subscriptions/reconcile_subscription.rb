module Cmd
  module Subscriptions
    class ReconcileSubscription
      Result = Struct.new(:success?, :subscription, :errors)

      def initialize(subscription_id:, source_job: "manual", window_days: nil)
        @subscription = Subscription.find_by(id: subscription_id)
        @source_job = source_job.to_s
        @window_days = window_days
      end

      def call
        return Result.new(false, nil, "Assinatura nao encontrada") if @subscription.blank?

        @local_status_before = @subscription.status
        @gateway_status = nil
        @raw_payload = {}
        @gateway_identifier = gateway_identifier

        case @subscription.company&.payment_method
        when "credit_card"
          if @subscription.external_subscription_id.blank?
            return register_and_return_error("Assinatura de cartao sem preapproval_id para reconciliacao")
          end
          reconcile_by_preapproval
        when "pix", "boleto"
          if @subscription.external_payment_id.blank?
            return register_and_return_error("Assinatura sem payment_id para reconciliacao")
          end
          reconcile_by_payment
        else
          register_and_return_error("Metodo de pagamento #{@subscription.company&.payment_method.inspect} nao suportado na reconciliacao")
        end
      rescue StandardError => e
        register_error_event_best_effort(e.message)
        Result.new(false, @subscription, e.message)
      end

      private

      def reconcile_by_payment
        payment = MercadoPago::Subscriptions.fetch_payment(@subscription.external_payment_id)
        return register_and_return_error("Pagamento #{@subscription.external_payment_id} nao encontrado no gateway") if payment.blank?

        @gateway_status = payment["status"].to_s
        @raw_payload = payment
        @gateway_identifier = payment["id"].to_s.presence || @subscription.external_payment_id

        @subscription.with_lock do
          @subscription.update!(
            external_payment_id: @gateway_identifier,
            raw_payload: payment
          )

          apply_gateway_status(payment["status"], approved_at: parse_time(payment["date_approved"]))
        end

        register_and_return_success
      end

      def reconcile_by_preapproval
        preapproval = MercadoPago::Subscriptions.fetch_preapproval(@subscription.external_subscription_id)
        return register_and_return_error("Preapproval #{@subscription.external_subscription_id} nao encontrado no gateway") if preapproval.blank?

        @gateway_status = preapproval["status"].to_s
        @raw_payload = preapproval
        @gateway_identifier = preapproval["id"].to_s.presence || @subscription.external_subscription_id

        @subscription.with_lock do
          @subscription.update!(
            external_reference: @subscription.external_reference.presence || preapproval["external_reference"],
            raw_payload: preapproval
          )

          apply_gateway_status(preapproval["status"])
        end

        register_and_return_success
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

      def register_and_return_success
        register_event!(result_status: "success", error_message: nil)
        Result.new(true, @subscription, nil)
      end

      def register_and_return_error(message)
        register_error_event_best_effort(message)
        Result.new(false, @subscription, message)
      end

      def register_event!(result_status:, error_message:)
        return if @subscription.blank?

        local_status_after = @subscription.status
        expected_local_status = expected_local_status_from_gateway(@gateway_status)
        divergent_before = expected_local_status.present? && @local_status_before.to_s != expected_local_status
        divergent_after = expected_local_status.present? && local_status_after.to_s != expected_local_status
        divergent = divergent_after
        resolved = divergent_before && !divergent_after && result_status == "success"

        SubscriptionReconciliationEvent.create!(
          subscription: @subscription,
          company: @subscription.company,
          source_job: @source_job,
          window_days: @window_days,
          payment_method: @subscription.company&.payment_method.to_s,
          gateway_identifier: @gateway_identifier.to_s.presence || gateway_identifier,
          gateway_status: @gateway_status,
          local_status_before: @local_status_before.to_s,
          local_status_after: local_status_after.to_s,
          divergent: divergent,
          resolved: resolved,
          result_status: result_status,
          error_message: error_message,
          raw_payload: @raw_payload.presence || {},
          processed_at: Time.current
        )
      end

      def gateway_identifier
        @subscription.external_payment_id.presence || @subscription.external_subscription_id.presence || @subscription.id.to_s
      end

      def expected_local_status_from_gateway(gateway_status)
        case gateway_status.to_s.downcase
        when "approved", "authorized"
          "active"
        when "cancelled", "canceled", "paused", "rejected"
          "cancelled"
        when "pending", "in_process"
          "pending"
        else
          nil
        end
      end

      def register_error_event_best_effort(message)
        register_event!(result_status: "error", error_message: message)
      rescue StandardError => event_error
        Rails.logger.error("[Cmd::Subscriptions::ReconcileSubscription] Falha ao registrar evento de erro da assinatura #{@subscription&.id}: #{event_error.message}")
      end
    end
  end
end
