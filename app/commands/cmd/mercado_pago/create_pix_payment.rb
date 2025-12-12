module Cmd
  module MercadoPago
    class CreatePixPayment
      attr_reader :company, :plan, :response

      def initialize(company)
        @company = company
        @plan = company.plan
      end

      def call
        @response = ::MercadoPago::Client.new.request(
          method: :post,
          path: '/v1/payments',
          body: pix_params,
        )

        if response['status'].include?('pending')
          Payments::PixMailer.with(mailer_params).pix_email.deliver_later
        else
          raise "Failed to create pix payment: #{response['status_detail']}"
        end
      rescue => e
        Rails.logger.error("Erro ao criar pix para a company id #{@company.id}: #{e.message}")
      end

      private

      def mailer_params
        {
          company: company,
          pix_code: response['point_of_interaction']['transaction_data']['qr_code'],
          pix_image_url: response['point_of_interaction']['transaction_data']['qr_code_base64'],
          pix_expiration_date: response['date_of_expiration'],
          pix_ticket_url: response['point_of_interaction']['transaction_data']['ticket_url']
        }
      end

      def pix_params
        payer_name = company.responsible.name
        {
          transaction_amount: plan.transaction_amount.to_i,
          payment_method_id: 'pix',
          description: "Assinatura do plano #{plan.name}",
          external_reference: company.id.to_s,
          additional_info: {
            items: [
              id: plan.id,
              title: plan.name,
              quantity: 1,
              unit_price: plan.transaction_amount.to_i
            ]
          },
          payer: {
            email: @company.email,
            first_name: payer_name.split(/\s+/).first,
            last_name: payer_name.split(/\s+/).last || '',
            identification: {
              type: @company.document.length == 11 ? 'CPF' : 'CNPJ',
              number: @company.document
            }
          }
        }
      end
    end
  end
end