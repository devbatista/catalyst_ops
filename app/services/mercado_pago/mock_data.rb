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

    def self.fetch_payment(
      payment_id,
      external_reference:,
      status: "pending",
      status_detail: "pending_waiting_payment",
      payment_method_id: "bolbradesco",
      payment_type_id: "ticket",
      transaction_amount: 0,
      payer_email: nil,
      company_name: nil
    )
      now = Time.current.iso8601
      amount = transaction_amount.to_d

      {
        "id" => payment_id.to_s,
        "date_created" => now,
        "date_last_updated" => now,
        "date_approved" => (status == "approved" ? now : nil),
        "external_reference" => external_reference.to_s,
        "status" => status,
        "status_detail" => status_detail,
        "payment_method_id" => payment_method_id,
        "payment_type_id" => payment_type_id,
        "currency_id" => "BRL",
        "transaction_amount" => amount,
        "transaction_details" => {
          "net_received_amount" => (status == "approved" ? amount : 0),
          "total_paid_amount" => (status == "approved" ? amount : 0),
          "external_resource_url" => (
            payment_type_id == "ticket" ? "https://www.mercadopago.com.br/payments/mock-boleto.pdf" : nil
          )
        },
        "payer" => {
          "email" => payer_email,
          "first_name" => company_name.to_s.split.first.presence || "Cliente",
          "last_name" => company_name.to_s.split.drop(1).join(" ").presence || "Teste",
          "identification" => {
            "type" => "CNPJ",
            "number" => "61408507000173"
          }
        },
        "metadata" => {
          "environment" => Rails.env,
          "mock" => true
        }
      }
    end
  end
end
