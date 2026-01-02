module Cmd
  module Subscriptions
    class CycleSubscription
      Result = Struct.new(:success?, :subscription, :errors)

      def initialize(subscription_id:)
        @subscription = Subscription.find_by(id: subscription_id)
        @company = @subscription.company
      end

      def call
        return unless Rails.env.production?
        
        payment_method = @subscription.company.payment_method

        case payment_method
        when 'boleto'
          Cmd::MercadoPago::CreateBoletoPayment.new(@company).call
        when 'pix'
          
        else
          raise "Método de pagamento desconhecido: #{payment_method}"
        end
      end
    end
  end
end