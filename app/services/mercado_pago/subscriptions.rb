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
      return mock_preapproval(preapproval_id) unless Rails.env.production?

      client.request(method: :get, path: "/preapproval/#{preapproval_id}")
    rescue StandardError => e
      Rails.logger.error("[MercadoPago::Subscriptions] Erro ao consultar preapproval #{preapproval_id}: #{e.message}")
      nil
    end

    def self.fetch_payment(payment_id)
      client.request(method: :get, path: "/v1/payments/#{payment_id}")
    rescue StandardError => e
      Rails.logger.error("[MercadoPago::Subscriptions] Erro ao consultar payment #{payment_id}: #{e.message}")
      nil
    end

    def self.fetch_authorized_payment(authorized_payment_id)
      return mock_authorized_payment(authorized_payment_id) unless Rails.env.production?

      client.request(method: :get, path: "/authorized_payments/#{authorized_payment_id}")
    rescue StandardError => e
      Rails.logger.error("[MercadoPago::Subscriptions] Erro ao consultar authorized payment #{authorized_payment_id}: #{e.message}")
      nil
    end

    def self.compute_period_end(paid_at, frequency: 1, frequency_type: "months")
      return if paid_at.blank?

      case frequency_type.to_s
      when "days"
        paid_at + frequency.to_i.days
      when "weeks"
        paid_at + frequency.to_i.weeks
      else
        paid_at + frequency.to_i.months
      end
    end

    def self.mock_preapproval(preapproval_id)
      subscription = Subscription.find_by(external_subscription_id: preapproval_id)
      return if subscription.blank?

      MercadoPago::MockData.fetch_preapproval(
        preapproval_id,
        external_reference: subscription.external_reference,
        preapproval_plan_id: subscription.preapproval_plan_id,
        payer_email: subscription.company.email,
        reason: subscription.reason,
        status: subscription.status == "pending" ? "pending" : "authorized"
      )
    end

    def self.mock_authorized_payment(authorized_payment_id)
      subscription = Subscription.where.not(external_subscription_id: nil).order(updated_at: :desc).first
      return if subscription.blank?

      MercadoPago::MockData.fetch_authorized_payment(
        authorized_payment_id,
        preapproval_id: subscription.external_subscription_id
      )
    end
  end
end
