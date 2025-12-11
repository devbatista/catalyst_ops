module Cmd
  module MercadoPago
    class CreateBoletoPayment
      def initialize(company)
        @company = company
        @plan = company.plan
      end

      def call
        response = MercadoPago::Client.new.request(
          method: :post,
          path: '/v1/payments',
          params: boleto_params
        )
      end

      private
      
      def boleto_params
        payer_name = @company.responsible.name
        {
          transaction_amount: @plan.transaction_amount.to_i,
          payment_method_id: 'bolbradesco',
          payer: {
            email: @company.email,
            first_name: payer_name.split(' ').first,
            last_name: payer_name.split(' ').last || '',
            identification: {
              type: @company.document.length == 11 ? 'CPF' : 'CNPJ',
              number: @company.document
            },
            address: {
              zip_code: '12345678',
              street_name: 'Rua Exemplo',
              street_number: '123',
              neighborhood: 'Bairro Exemplo',
              city: 'Cidade Exemplo',
              federal_unit: 'SP'
            }
          }
        }
      end
    end
  end
end