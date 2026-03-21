class WebHook::MercadoPagoController < WebHookController
  skip_before_action :verify_authenticity_token
  
  def webhook
    raw = request.raw_post
    Rails.logger.info("Recebido webhook do Mercado Pago: #{raw}")
    
    payload = JSON.parse(raw)
    result = MercadoPago::WebhookProcessor.new(payload: payload).call

    if result.success?
      Rails.logger.info("[WebHook::MercadoPagoController] #{result.message}")
      render json: { status: "ok" }, status: :ok
    else
      Rails.logger.error("[WebHook::MercadoPagoController] #{result.message}")
      render json: { status: "error", message: result.message }, status: :unprocessable_entity
    end
  rescue JSON::ParserError => e
    Rails.logger.error("Payload invalido no webhook do Mercado Pago: #{e.message}")
    render json: { status: "invalid_payload" }, status: :bad_request
  end

  def webhook_test
    
  end
end
