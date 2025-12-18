module Cmd
  module MercadoPago
    class CreateCreditCardPayment
      attr_reader :company, :plan, :cc_token, :response

      def initialize(company, cc_token)
        @company = company
        @plan = company.plan
        @cc_token = cc_token || 'b11e1570a64670e09c6df6585c8e2c57'
      end

      def call
        @response = ::MercadoPago::Client.new.request(
          method: :post,
          path: '/preapproval',
          body: credit_card_params,
        )

        if response['status'] == 'pending'
          Payments::CreditCardMailer.with(company: company, payment_url: url).credit_card_email.deliver_later
        else
          raise "Failed to create credit card payment: #{response['status_detail']}"
        end
      rescue => e
        Rails.logger.error("Erro ao criar solicitação de pagamento para a company id #{@company.id}: #{e.message}")
      end

      private

      def mailer_params
        {
          company: company,
          plan: plan,
        }
      end

      def credit_card_params
        {
          preapproval_plan_id: plan.external_id,
          reason: plan.reason,
          external_reference: company.id.to_s,
          payer_email: company.email,
          card_token_id: cc_token,
          auto_recurring: {
            frequency: 1,
            frequency_type: 'months',
            transaction_amount: plan.transaction_amount.to_i,
            currency_id: 'BRL',
          },
          back_url: 'https://yourapp.com/payment_success',
          notification_url: 'https://yourapp.com/mercado_pago_notifications',
          status: 'authorized'
        }
      end
    end
  end
end