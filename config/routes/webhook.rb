constraints subdomain: "webhook" do
  post "/mp", to: "web_hook/mercado_pago#webhook", as: :mercado_pago_webhook
  post "/mp/test", to: "web_hook/mercado_pago#webhook_test", as: :mercado_pago_webhook_test
end