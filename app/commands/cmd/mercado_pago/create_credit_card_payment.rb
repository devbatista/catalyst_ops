module Cmd
  module MercadoPago
    class CreateCreditCardPayment
      Result = Struct.new(:success?, :subscription, :errors)
      attr_reader :company, :plan, :cc_token, :response

      def initialize(company, cc_token)
        @company = company
        @plan = company.plan
        @cc_token = cc_token
      end

      def call
        @response = if Rails.env.production?
          ::MercadoPago::Client.new.request(
            method: :post,
            path: '/preapproval',
            body: credit_card_params,
          )
        else
          ::MercadoPago::MockData.create_credit_card_payment(credit_card_params)
        end

        subscription = company.current_subscription

        subscription.update!(
          external_reference: company.id.to_s,
          external_subscription_id: response["id"],
          raw_payload: response
        )

        case response["status"]
        when "authorized"
          subscription.activate!
          Result.new(true, subscription, nil)
        when "pending"
          subscription.update!(status: :pending)
          Result.new(true, subscription, nil)
        else
          raise "Failed to create credit card payment: #{response['status_detail']}"
        end
      rescue => e
        Rails.logger.error("Erro ao criar solicitação de pagamento para a company id #{@company.id}: #{e.message}")
        Result.new(false, company.current_subscription, e.message)
      end

      private

      def credit_card_params
        {
          preapproval_plan_id: plan.external_id,
          reason: plan.reason,
          external_reference: company.id.to_s,
          payer_email: company.email,
          card_token_id: cc_token,
          status: 'authorized'
        }
      end
    end
  end
end
