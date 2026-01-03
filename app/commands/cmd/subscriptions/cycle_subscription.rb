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
          create_boleto_payment
        when 'pix'
          create_pix_payment
        else
          raise "Método de pagamento desconhecido: #{payment_method}"
        end
      end

      private

      def create_boleto_payment
        result = Cmd::MercadoPago::CreateBoletoPayment.new(@company).call

        if result.success?
          Subscriptions::BoletoMailer.with(result.mailer_params).ticket_email.deliver_later
        else
          raise "Falha ao criar pagamento via boleto: #{result.errors}"
        end
      rescue => e
        Rails.logger.error("Erro ao ciclar assinatura ID #{@subscription.id}: #{e.message}")
      end

      def create_pix_payment
        result = Cmd::MercadoPago::CreatePixPayment.new(@company).call

        if result.success?
          Subscriptions::PixMailer.with(result.mailer_params).pix_email.deliver_later
        else
          raise "Falha ao criar pagamento Pix: #{result.errors}"
        end
      rescue => e
        Rails.logger.error("Erro ao ciclar assinatura ID #{@subscription.id}: #{e.message}")
      end
    end
  end
end