require "digest"
require "openssl"

class WebHook::MercadoPagoController < WebHookController
  skip_before_action :verify_authenticity_token
  
  def webhook
    raw = request.raw_post
    Rails.logger.info("Recebido webhook do Mercado Pago: #{raw}")
    
    payload = JSON.parse(raw)

    unless webhook_signature_valid?(payload)
      Rails.logger.warn("[WebHook::MercadoPagoController] Assinatura de webhook invalida")
      render json: { status: "unauthorized" }, status: :unauthorized
      return
    end

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
    status = payload_status(payload)
    signature_ts = signature_timestamp_from_header
    fallback = [type, resource_id, action, status, signature_ts].compact.join(":")

    fallback.presence || Digest::SHA256.hexdigest(payload.to_json)
  end

  def payload_resource_id(payload)
    payload.dig("data", "id").presence || payload["id"].to_s.presence
  end

  def payload_event_type(payload)
    payload["type"].presence || payload["topic"].presence || "unknown"
  end

  def payload_status(payload)
    payload.dig("data", "status").presence || payload["status"].presence
  end

  def webhook_signature_valid?(payload)
    secret = ENV.fetch("MP_WEBHOOK_SECRET", "").to_s.strip
    signature_header = request_header("x-signature")
    request_id = request_header("x-request-id")

    if secret.blank?
      if signature_validation_required?
        Rails.logger.error("[WebHook::MercadoPagoController] MP_WEBHOOK_SECRET ausente para validacao obrigatoria de assinatura")
        return false
      end

      Rails.logger.warn("[WebHook::MercadoPagoController] MP_WEBHOOK_SECRET ausente; validacao de assinatura ignorada fora de producao")
      return true
    end

    if signature_header.blank?
      return false if signature_validation_required?

      Rails.logger.warn("[WebHook::MercadoPagoController] x-signature ausente; validacao de assinatura ignorada fora de producao")
      return true
    end

    ts, signature_v1 = parse_signature_header(signature_header)
    return false if ts.blank? || signature_v1.blank?

    data_id = payload_resource_id(payload).to_s
    data_id = data_id.downcase if data_id.match?(/\A[a-zA-Z0-9]+\z/)

    manifest = +""
    manifest << "id:#{data_id};" if data_id.present?
    manifest << "request-id:#{request_id};" if request_id.present?
    manifest << "ts:#{ts};"

    expected = OpenSSL::HMAC.hexdigest("SHA256", secret, manifest)
    secure_compare_hexdigest(expected, signature_v1)
  end

  def parse_signature_header(signature_header)
    ts = nil
    v1 = nil

    signature_header.to_s.split(",").each do |part|
      key, value = part.split("=", 2)
      next if key.blank? || value.blank?

      normalized_key = key.strip.downcase
      normalized_value = value.strip

      ts = normalized_value if normalized_key == "ts"
      v1 = normalized_value if normalized_key == "v1"
    end

    [ts, v1]
  end

  def signature_timestamp_from_header
    signature_header = request_header("x-signature")
    return nil if signature_header.blank?

    ts, = parse_signature_header(signature_header)
    ts.presence
  end

  def secure_compare_hexdigest(expected, provided)
    return false if expected.blank? || provided.blank?
    return false unless expected.bytesize == provided.bytesize

    ActiveSupport::SecurityUtils.secure_compare(expected, provided)
  end

  def signature_validation_required?
    Rails.env.production? || ENV["MP_WEBHOOK_REQUIRE_SIGNATURE"] == "true"
  end

  def request_header(name)
    request.headers[name].presence ||
      request.headers[name.upcase].presence ||
      request.headers["HTTP_#{name.upcase.tr('-', '_')}"].presence
  end
end
