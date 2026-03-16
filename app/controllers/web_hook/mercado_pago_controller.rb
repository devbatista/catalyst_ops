class WebHook::MercadoPagoController < ApplicationController
  def webhook
    Rails.logger.info("Recebido webhook do Mercado Pago: #{request.raw_post}")
    head :ok
  end
end