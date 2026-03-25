require "digest"

class WebHook::MercadoPagoController < WebHookController
  skip_before_action :verify_authenticity_token
  
  def webhook
    raw = request.raw_post
    Rails.logger.info("Recebido webhook do Mercado Pago: #{raw}")
    
    payload = JSON.parse(raw)
    event = find_or_create_event!(payload)

    if event.status == "processed"
      Rails.logger.info("[WebHook::MercadoPagoController] Webhook duplicado ignorado: #{event.event_key}")
      head :no_content
      return
    end

    response_status = :ok
    response_body = { status: "ok" }

    event.with_lock do
      event.reload

      if event.status == "processed"
        response_status = :no_content
        response_body = nil
        next
      end

      event.update!(
        status: "processing",
        resource_id: payload_resource_id(payload),
        event_type: payload_event_type(payload),
        payload: payload,
        error_message: nil
      )

      result = MercadoPago::WebhookProcessor.new(payload: payload).call

      if result.success?
        event.update!(status: "processed", processed_at: Time.current, error_message: nil)
        Rails.logger.info("[WebHook::MercadoPagoController] #{result.message}")
        response_status = :ok
        response_body = { status: "ok" }
      else
        event.update!(status: "failed", error_message: result.message)
        Rails.logger.error("[WebHook::MercadoPagoController] #{result.message}")
        response_status = :unprocessable_entity
        response_body = { status: "error", message: result.message }
      end
    end

    if response_status == :no_content
      head :no_content
    else
      render json: response_body, status: response_status
    end
  rescue JSON::ParserError => e
    Rails.logger.error("Payload invalido no webhook do Mercado Pago: #{e.message}")
    render json: { status: "invalid_payload" }, status: :bad_request
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[WebHook::MercadoPagoController] Erro ao persistir webhook: #{e.message}")
    render json: { status: "error", message: "invalid_webhook_event" }, status: :unprocessable_entity
  end

  def webhook_test
    
  end

  private

  def find_or_create_event!(payload)
    event_key = payload_event_key(payload)
    attrs = {
      provider: WebhookEvent::PROVIDER_MERCADO_PAGO,
      event_key: event_key
    }

    WebhookEvent.find_or_create_by!(attrs) do |event|
      event.resource_id = payload_resource_id(payload)
      event.event_type = payload_event_type(payload)
      event.payload = payload
      event.status = "received"
    end
  rescue ActiveRecord::RecordNotUnique
    WebhookEvent.find_by!(provider: WebhookEvent::PROVIDER_MERCADO_PAGO, event_key: event_key)
  end

  def payload_event_key(payload)
    request_id = request.headers["x-request-id"].to_s.presence || request.headers["X-Request-Id"].to_s.presence
    return request_id if request_id.present?

    type = payload_event_type(payload)
    resource_id = payload_resource_id(payload)
    action = payload["action"].to_s
    fallback = [type, resource_id, action].compact.join(":")

    fallback.presence || Digest::SHA256.hexdigest(payload.to_json)
  end

  def payload_resource_id(payload)
    payload.dig("data", "id").presence || payload["id"].to_s.presence
  end

  def payload_event_type(payload)
    payload["type"].presence || payload["topic"].presence || "unknown"
  end
end
