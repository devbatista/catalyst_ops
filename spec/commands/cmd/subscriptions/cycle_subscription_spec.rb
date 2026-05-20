require "rails_helper"

RSpec.describe Cmd::Subscriptions::CycleSubscription do
  describe "#call" do
    it "não executa integração fora de produção" do
      subscription = create(:subscription)

      allow(Rails.env).to receive(:production?).and_return(false)
      expect(Cmd::MercadoPago::CreateBoletoPayment).not_to receive(:new)
      expect(Cmd::MercadoPago::CreatePixPayment).not_to receive(:new)

      expect(described_class.new(subscription_id: subscription.id).call).to be_nil
    end

    it "cria pagamento por boleto e envia e-mail em produção" do
      company = company_with_subscription(payment_method: "boleto")
      subscription = company.current_subscription
      payment_result = Cmd::MercadoPago::CreateBoletoPayment::Result.new(true, { company: company, boleto_url: "https://boleto" }, nil)
      command = instance_double(Cmd::MercadoPago::CreateBoletoPayment, call: payment_result)
      mail = instance_double(ActionMailer::MessageDelivery, deliver_later: true)

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(Cmd::MercadoPago::CreateBoletoPayment).to receive(:new).with(company).and_return(command)
      allow(Subscriptions::BoletoMailer).to receive(:with).and_return(double(ticket_email: mail))

      described_class.new(subscription_id: subscription.id).call

      expect(mail).to have_received(:deliver_later)
    end

    it "cria pagamento por pix e envia e-mail em produção" do
      company = company_with_subscription(payment_method: "pix")
      subscription = company.current_subscription
      payment_result = Cmd::MercadoPago::CreatePixPayment::Result.new(true, { company: company, pix_code: "codigo" }, nil)
      command = instance_double(Cmd::MercadoPago::CreatePixPayment, call: payment_result)
      mail = instance_double(ActionMailer::MessageDelivery, deliver_later: true)

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(Cmd::MercadoPago::CreatePixPayment).to receive(:new).with(company).and_return(command)
      allow(Subscriptions::PixMailer).to receive(:with).and_return(double(pix_email: mail))

      described_class.new(subscription_id: subscription.id).call

      expect(mail).to have_received(:deliver_later)
    end

    it "levanta erro para método de pagamento desconhecido" do
      company = company_with_subscription(payment_method: "boleto")
      company.update_columns(payment_method: "dinheiro")

      allow(Rails.env).to receive(:production?).and_return(true)

      expect do
        described_class.new(subscription_id: company.current_subscription.id).call
      end.to raise_error(RuntimeError, "Método de pagamento desconhecido: dinheiro")
    end

    it "registra erro quando integração de boleto falha" do
      company = company_with_subscription(payment_method: "boleto")
      subscription = company.current_subscription
      payment_result = Cmd::MercadoPago::CreateBoletoPayment::Result.new(false, nil, "erro externo")
      command = instance_double(Cmd::MercadoPago::CreateBoletoPayment, call: payment_result)

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(Cmd::MercadoPago::CreateBoletoPayment).to receive(:new).with(company).and_return(command)
      allow(Rails.logger).to receive(:error)

      described_class.new(subscription_id: subscription.id).call

      expect(Rails.logger).to have_received(:error).with("Erro ao ciclar assinatura ID #{subscription.id}: Falha ao criar pagamento via boleto: erro externo")
    end
  end

  def company_with_subscription(payment_method:)
    plan = create(:plan)
    company = create(:company, plan: plan, payment_method: payment_method)
    create(:subscription, company: company, subscription_plan: plan, status: :active)
    company.reload
  end
end
