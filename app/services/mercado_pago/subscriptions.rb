module MercadoPago
  class Subscriptions
    def self.client
      @client ||= MercadoPago::Client.new
    end

    def self.start(company:, payer_email:, amount:, reason:, back_url:, frequency: 1, frequency_type: 'months')
      # ...esboço...
      # payload do preapproval (payer_email, reason, external_reference, auto_recurring, back_url)
      # POST /preapproval -> salva/atualiza Subscription (mp_preapproval_id, external_reference, status)
      # retorna body["init_point"]
    end

    def self.fetch_preapproval(preapproval_id)
      # ...esboço... (GET /preapproval/:id -> retorna hash ou nil)
    end

    def self.fetch_payment(payment_id)
      # ...esboço... (GET /v1/payments/:id -> retorna hash ou nil)
    end

    def self.compute_period_end(paid_at, frequency: 1, frequency_type: "months")
      # ...esboço... (padrão: paid_at + 1.month)
    end
  end
end