module Cmd
  module MercadoPago
    class CreateBoletoPayment
      attr_reader :company, :plan, :response

      def initialize(company)
        @company = company
        @plan = company.plan
      end

      def call
        @response = ::MercadoPago::Client.new.request(
          method: :post,
          path: '/v1/payments',
          body: boleto_params
        )

        if response['status'].include?('pending')
          Payments::BoletoMailer.with(mailer_params).ticket_email.deliver_later
        else
          raise "Failed to create boleto payment: #{response['status_detail']}"
        end
      rescue => e
        Rails.logger.error("Erro ao criar boleto para a company id #{@company.id}: #{e.message}")
      end

      private

      def mailer_params
        {
          company: company,
          boleto_url: response['transaction_details']['external_resource_url'],
          boleto_expiration_date: response['date_of_expiration'],
          boleto_barcode: response['barcode']['content']
        }
      end
      
      def boleto_params
        payer_name = company.responsible.name
        {
          transaction_amount: plan.transaction_amount.to_i,
          payment_method_id: 'bolbradesco',
          description: "Assinatura mensal do plano #{plan.name}",
          external_reference: company.id.to_s,
          date_of_expiration: (Date.today + 7.days).end_of_day.iso8601,
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
            },
            address: {
              zip_code: @company.formatted_zip_code,
              street_name: @company.street,
              street_number: @company.number,
              neighborhood: @company.neighborhood,
              city: @company.city,
              federal_unit: @company.state
            }
          }
        }
      end
    end
  end
end