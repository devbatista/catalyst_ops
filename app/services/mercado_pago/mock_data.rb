module MercadoPago
  class MockData
    DEFAULT_PREAPPROVAL_ID = "2c938084726fca480172750000000111".freeze
    DEFAULT_AUTHORIZED_PAYMENT_ID = "authorized-payment-000111".freeze

    def self.create_credit_card_payment(params)
      now = Time.current.iso8601

      {
        "id" => DEFAULT_PREAPPROVAL_ID,
        "client_id" => 123456789,
        "collector_id" => 123456789,
        "application_id" => 1234567890123456,
        "back_url" => "https://www.seusite.com.br/voltar",
        "reason" => params[:reason],
        "external_reference" => params[:external_reference],
        "auto_recurring" => {
          "frequency" => 1,
          "frequency_type" => "months",
          "transaction_amount" => params.dig(:auto_recurring, :transaction_amount) || 5.0,
          "currency_id" => "BRL"
        },
        "init_point" => "https://www.mercadopago.com.br/subscriptions/checkout?preapproval_id=#{DEFAULT_PREAPPROVAL_ID}",
        "sandbox_init_point" => "https://sandbox.mercadopago.com.br/subscriptions/checkout?preapproval_id=#{DEFAULT_PREAPPROVAL_ID}",
        "payer_id" => 987654321,
        "payer_email" => params[:payer_email],
        "card_id" => "123456abcdef",
        "payment_method_id" => "master",
        "status" => params[:status] || "authorized",
        "date_created" => now,
        "last_modified" => now,
        "preapproval_plan_id" => params[:preapproval_plan_id],
        "status_detail" => "authorized"
      }
    end

    def self.fetch_preapproval(preapproval_id, external_reference: nil, preapproval_plan_id: nil, payer_email: nil, reason: nil, status: "authorized")
      now = Time.current.iso8601

      {
        "id" => preapproval_id,
        "external_reference" => external_reference.to_s,
        "preapproval_plan_id" => preapproval_plan_id,
        "payer_email" => payer_email,
        "reason" => reason,
        "status" => status,
        "date_created" => now,
        "last_modified" => now,
        "auto_recurring" => {
          "frequency" => 1,
          "frequency_type" => "months",
          "transaction_amount" => 5.0,
          "currency_id" => "BRL"
        }
      }
    end

    def self.fetch_authorized_payment(authorized_payment_id, preapproval_id:, status: "approved")
      {
        "id" => authorized_payment_id,
        "preapproval_id" => preapproval_id,
        "debit_date" => Time.current.iso8601,
        "payment" => {
          "status" => status
        }
      }
    end
  end
end
