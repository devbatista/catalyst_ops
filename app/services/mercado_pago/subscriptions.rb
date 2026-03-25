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

    def self.fetch_payment(payment_id, mock_status: nil)
      return mock_payment(payment_id, mock_status: mock_status) unless Rails.env.production?

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

    def self.mock_payment(payment_id, mock_status: nil)
      subscription = Subscription.find_by(external_payment_id: payment_id.to_s) ||
        Subscription.find_by(external_reference: payment_id.to_s) ||
        Subscription.order(updated_at: :desc).first
      return if subscription.blank?

      company = subscription.company
      payment_status =
        case mock_status.to_s.downcase.presence || "approved"
        when "approved"
          "approved"
        when "cancelled", "canceled", "expired"
          "cancelled"
        when "rejected"
          "rejected"
        when "in_process"
          "in_process"
        else
          "approved"
        end

      payment_method = company&.payment_method.to_s
      payment_type_id =
        case payment_method
        when "boleto"
          "ticket"
        when "pix"
          "bank_transfer"
        when "credit_card"
          "credit_card"
        else
          "ticket"
        end

      payment_method_id =
        case payment_method
        when "boleto"
          "bolbradesco"
        when "pix"
          "pix"
        when "credit_card"
          "master"
        else
          "bolbradesco"
        end

      MercadoPago::MockData.fetch_payment(
        payment_id,
        external_reference: subscription.external_reference.presence || company&.id.to_s,
        status: payment_status,
        status_detail: mock_payment_status_detail(payment_status),
        payment_method_id: payment_method_id,
        payment_type_id: payment_type_id,
        transaction_amount: subscription.transaction_amount.to_d,
        payer_email: company&.email,
        company_name: company&.name
      )
    end

    def self.mock_payment_status_detail(payment_status)
      case payment_status
      when "approved"
        "accredited"
      when "cancelled"
        "by_collector"
      when "rejected"
        "cc_rejected_other_reason"
      when "in_process"
        "pending_contingency"
      else
        "pending_waiting_payment"
      end
    end
  end
end
