require "rails_helper"

RSpec.describe Cmd::MercadoPago::CreateBoletoPayment do
  describe "#call" do
    it "envia payload para API, persiste payment_id e monta parâmetros do mailer" do
      company = company_with_subscription(payment_method: "boleto")
      client = instance_double(MercadoPago::Client)
      response = boleto_response(status: "pending", id: "boleto_123")
      sent_body = nil

      allow(MercadoPago::Client).to receive(:new).and_return(client)
      allow(client).to receive(:request) do |method:, path:, body:|
        expect(method).to eq(:post)
        expect(path).to eq("/v1/payments")
        sent_body = body
        response
      end

      result = described_class.new(company).call

      aggregate_failures do
        expect(result).to be_success
        expect(sent_body).to include(
          transaction_amount: company.plan.transaction_amount.to_f,
          payment_method_id: "bolbradesco",
          external_reference: company.id.to_s
        )
        expect(sent_body[:payer]).to include(email: company.email)
        expect(company.current_subscription.reload.external_payment_id).to eq("boleto_123")
        expect(result.mailer_params).to include(
          company: company,
          boleto_url: "https://boleto.example",
          boleto_expiration_date: response["date_of_expiration"],
          boleto_barcode: "123456",
          external_id: "boleto_123"
        )
      end
    end

    it "retorna erro quando status não é pending" do
      company = company_with_subscription(payment_method: "boleto")
      client = instance_double(MercadoPago::Client, request: boleto_response(status: "rejected", status_detail: "cc_rejected"))

      allow(MercadoPago::Client).to receive(:new).and_return(client)

      result = described_class.new(company).call

      aggregate_failures do
        expect(result).not_to be_success
        expect(result.errors).to eq("Falha ao criar o pagamento via boleto: cc_rejected")
      end
    end

    it "retorna erro quando integração levanta exceção" do
      company = company_with_subscription(payment_method: "boleto")
      client = instance_double(MercadoPago::Client)

      allow(MercadoPago::Client).to receive(:new).and_return(client)
      allow(client).to receive(:request).and_raise(StandardError, "timeout")
      allow(Rails.logger).to receive(:error)

      result = described_class.new(company).call

      aggregate_failures do
        expect(result).not_to be_success
        expect(result.errors).to eq(" Erro ao criar o pagamento via boleto: timeout")
        expect(Rails.logger).to have_received(:error).with("Erro ao criar boleto para a company id #{company.id}: timeout")
      end
    end
  end

  def company_with_subscription(payment_method:)
    plan = create(:plan)
    company = create(:company, plan: plan, payment_method: payment_method)
    responsible = create(:user, :gestor, company: company)
    company.update!(responsible: responsible)
    create(:subscription, company: company, subscription_plan: plan, status: :active)
    company.reload
  end

  def boleto_response(status:, id: "boleto_123", status_detail: "pending_waiting_payment")
    {
      "id" => id,
      "status" => status,
      "status_detail" => status_detail,
      "date_of_expiration" => "2026-05-27T23:59:59.000-03:00",
      "transaction_details" => { "external_resource_url" => "https://boleto.example" },
      "barcode" => { "content" => "123456" }
    }
  end
end
