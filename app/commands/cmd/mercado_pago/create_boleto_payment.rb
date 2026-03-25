module Cmd
  module MercadoPago
    class CreateBoletoPayment
      Result = Struct.new(:success?, :mailer_params, :errors)
      attr_reader :company, :plan, :response

      def initialize(company, amount_override: nil)
        @company = company
        @plan = company.plan
        @amount_override = amount_override
      end

      def call
        @response = ::MercadoPago::Client.new.request(
          method: :post,
          path: '/v1/payments',
          body: boleto_params
        )

        if response['status'].include?('pending')
          persist_payment_reference!
          Result.new(true, mailer_params, nil)
        else
          error = "Falha ao criar o pagamento via boleto: #{response['status_detail']}"
          Result.new(false, nil, error)
        end
      rescue => e
        Rails.logger.error("Erro ao criar boleto para a company id #{@company.id}: #{e.message}")
        Result.new(false, nil, " Erro ao criar o pagamento via boleto: #{e.message}")
      end

      private

      def mailer_params
        {
          company: company,
          boleto_url: response['transaction_details']['external_resource_url'],
          boleto_expiration_date: response['date_of_expiration'],
          boleto_barcode: response['barcode']['content'],
          external_id: response['id']
        }
      end
      
      def boleto_params
        payer_name = company.responsible.name
        {
          transaction_amount: amount_to_charge.to_f,
          payment_method_id: 'bolbradesco',
          description: "Assinatura mensal do plano #{plan.name}",
          external_reference: company.id.to_s,
          date_of_expiration: (Date.today + 7.days).end_of_day.strftime("%Y-%m-%dT%H:%M:%S.000%:z"),
          additional_info: {
            items: [
              id: plan.id,
              title: plan.name,
              quantity: 1,
              unit_price: amount_to_charge.to_f
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

      def amount_to_charge
        @amount_to_charge ||= (@amount_override.presence || plan.transaction_amount).to_d.round(2)
      end

      def persist_payment_reference!
        payment_id = response['id'].to_s
        return if payment_id.blank?

        company.current_subscription&.update!(external_reference: payment_id)
      end
    end
  end
end
