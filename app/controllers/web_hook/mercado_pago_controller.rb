class WebHook::MercadoPagoController < WebHookController
  skip_before_action :verify_authenticity_token
  
  def webhook
    Rails.logger.info("Recebido webhook do Mercado Pago: #{request}")
      
    request = request.raw_post
    Rails.logger.info("Recebido webhook do Mercado Pago: #{request}")
    
    request = JSON.parse(request)
    payment_id = request['data']['id']

    subscription = Subscription.find_by(external_reference: payment_id)

    case request['type']
    when 'payment'
      activate_subscription(subscription)
    end
    
    render json: { status: 'ok' }, status: :ok
  end

  def webhook_test
    
  end

  private
  
  def activate_subscription(subscription)
    return unless subscription
    subscription.activate!
  end
end