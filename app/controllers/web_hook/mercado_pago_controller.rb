class WebHook::MercadoPagoController < WebHookController
  skip_before_action :verify_authenticity_token
  
  def webhook
    Rails.logger.info("Recebido webhook do Mercado Pago: #{request.raw_post}")
    
    render json: { status: 'ok' }, status: :ok
  end

  def webhook_test
    
  end
end