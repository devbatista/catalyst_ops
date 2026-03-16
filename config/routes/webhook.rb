constraints subdomain: "webhook" do
  post "/", to: "mercado_pago#webhook", as: :mercado_pago_webhook
end
