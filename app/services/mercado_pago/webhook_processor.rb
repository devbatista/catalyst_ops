module MercadoPago
  class WebhookProcessor
    Result = Struct.new(:success?, :message)

    def initialize(payload:)
      @payload = payload
    end

    def call
      case notification_type
      when "payment"
        process_payment
      when "subscription_preapproval"
        process_preapproval
      when "subscription_authorized_payment"
        process_authorized_payment
      else
        Result.new(true, "Webhook ignorado para tipo #{notification_type || 'desconhecido'}")
      end
    rescue StandardError => e
      Rails.logger.error("[MercadoPago::WebhookProcessor] Falha ao processar webhook: #{e.message}")
      Result.new(false, e.message)
    end

    private

    attr_reader :payload

    def notification_type
      payload["type"].presence || payload["topic"].presence
    end

    def resource_id
      payload.dig("data", "id").presence || payload["id"].presence
    end

    def process_payment
      payment_id = resource_id
      return Result.new(false, "Webhook de payment sem data.id") if payment_id.blank?

      payment = MercadoPago::Subscriptions.fetch_payment(payment_id)
      return Result.new(false, "Pagamento #{payment_id} nao encontrado na API") if payment.blank?

      company_id = payment["external_reference"].presence
      subscription = Company.find_by(id: company_id)&.current_subscription
      return Result.new(false, "Assinatura local nao encontrada para company #{company_id}") if subscription.blank?

      subscription.update!(raw_payload: payment)

      case payment["status"]
      when "approved"
        subscription.activate!
      when "cancelled"
        subscription.cancel!
      end

      Result.new(true, "Pagamento #{payment_id} processado com status #{payment['status']}")
    end

    def process_preapproval
      preapproval_id = resource_id
      return Result.new(false, "Webhook de subscription_preapproval sem data.id") if preapproval_id.blank?

      preapproval = MercadoPago::Subscriptions.fetch_preapproval(preapproval_id)
      return Result.new(false, "Preapproval #{preapproval_id} nao encontrado na API") if preapproval.blank?

      subscription = Subscription.find_by(external_subscription_id: preapproval_id) ||
        Company.find_by(id: preapproval["external_reference"])&.current_subscription
      return Result.new(false, "Assinatura nao encontrada para preapproval #{preapproval_id}") if subscription.blank?

      subscription.update!(
        external_reference: subscription.external_reference.presence || preapproval["external_reference"],
        external_subscription_id: preapproval_id,
        raw_payload: preapproval
      )

      case preapproval["status"]
      when "authorized"
        subscription.activate!
      when "paused", "cancelled"
        subscription.cancel!
      when "pending"
        subscription.update!(status: :pending)
      end

      Result.new(true, "Preapproval #{preapproval_id} processado com status #{preapproval['status']}")
    end

    def process_authorized_payment
      authorized_payment_id = resource_id
      return Result.new(false, "Webhook de subscription_authorized_payment sem data.id") if authorized_payment_id.blank?

      authorized_payment = MercadoPago::Subscriptions.fetch_authorized_payment(authorized_payment_id)
      return Result.new(false, "Authorized payment #{authorized_payment_id} nao encontrado na API") if authorized_payment.blank?

      subscription = Subscription.find_by(external_subscription_id: authorized_payment["preapproval_id"])
      return Result.new(false, "Assinatura nao encontrada para authorized payment #{authorized_payment_id}") if subscription.blank?

      subscription.update!(raw_payload: authorized_payment)

      return Result.new(true, "Authorized payment #{authorized_payment_id} ignorado com status #{authorized_payment.dig('payment', 'status')}") unless authorized_payment.dig("payment", "status") == "approved"

      paid_at = parse_time(authorized_payment["debit_date"]) || Time.current
      period_end = MercadoPago::Subscriptions.compute_period_end(paid_at)

      subscription.update!(
        status: :active,
        start_date: paid_at.to_date,
        end_date: period_end.to_date,
        canceled_date: nil,
        expired_date: nil,
        expiration_warning_sent_at: nil
      )

      Result.new(true, "Authorized payment #{authorized_payment_id} processado com sucesso")
    end

    def parse_time(value)
      return if value.blank?

      Time.zone.parse(value)
    rescue ArgumentError
      nil
    end
  end
end
