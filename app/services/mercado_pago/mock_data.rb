module MercadoPago
  class MockData
    def self.create_credit_card_payment(_params)
      {
        "id" => "2c938084726fca480172750000000111",
        "client_id" => 123456789,
        "collector_id" => 123456789,
        "application_id" => 1234567890123456,
        "back_url" => "https://www.seusite.com.br/voltar",
        "reason" => "Assinatura Premium",
        "external_reference" => "ref-001",
        "auto_recurring" => {
          "frequency" => 1,
          "frequency_type" => "months",
          "transaction_amount" => 5.0,
          "currency_id" => "BRL"
        },
        "init_point" => "https://www.mercadopago.com.br/subscriptions/checkout?preapproval_id=2c938084726fca480172750000000111",
        "sandbox_init_point" => "https://sandbox.mercadopago.com.br/subscriptions/checkout?preapproval_id=2c938084726fca480172750000000111",
        "payer_id" => 987654321,
        "payer_email" => "cliente_teste@email.com",
        "card_id" => "123456abcdef",
        "payment_method_id" => "master",
        "status" => "authorized",
        "date_created" => "2024-06-05T19:59:04.000-04:00",
        "last_modified" => "2024-06-05T19:59:04.000-04:00",
        "preapproval_plan_id" => "2c938084726fca480172750000000000",
        "status_detail" => "authorized"
      }
    end
  end
end