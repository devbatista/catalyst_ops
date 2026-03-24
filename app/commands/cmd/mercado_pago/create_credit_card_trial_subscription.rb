module Cmd
  module MercadoPago
    class CreateCreditCardTrialSubscription
      Result = Struct.new(:success?, :subscription, :errors)
      attr_reader :company, :plan, :cc_token, :coupon, :response

      def initialize(company, cc_token, coupon)
        @company = company
        @plan = company.plan
        @cc_token = cc_token
        @coupon = coupon
      end

      def call
        @response = if Rails.env.production?
          ::MercadoPago::Client.new.request(
            method: :post,
            path: "/preapproval",
            body: credit_card_trial_params
          )
        else
          ::MercadoPago::MockData.create_credit_card_payment(credit_card_trial_params)
        end

        subscription = company.current_subscription
        subscription.update!(
          external_reference: company.id.to_s,
          external_subscription_id: response["id"],
          raw_payload: response
        )

        case response["status"]
        when "authorized"
          subscription.activate_for!(
            frequency: coupon.trial_frequency,
            frequency_type: coupon.trial_frequency_type
          )
          Result.new(true, subscription, nil)
        when "pending"
          subscription.update!(status: :pending)
          Result.new(true, subscription, nil)
        else
          raise "Falha ao criar a assinatura de teste no cartão: #{response['status_detail']}"
        end
      rescue => e
        Rails.logger.error("Erro ao criar assinatura de teste no cartão para a company id #{@company.id}: #{e.message}")
        Result.new(false, company.current_subscription, e.message)
      end

      private

      def credit_card_trial_params
        {
          reason: plan.reason,
          external_reference: company.id.to_s,
          payer_email: company.email,
          card_token_id: cc_token,
          status: "authorized",
          auto_recurring: {
            frequency: plan.frequency,
            frequency_type: plan.frequency_type,
            transaction_amount: plan.transaction_amount.to_f,
            currency_id: "BRL",
            free_trial: {
              frequency: coupon.trial_frequency,
              frequency_type: coupon.trial_frequency_type
            }
          }
        }
      end
    end
  end
end
