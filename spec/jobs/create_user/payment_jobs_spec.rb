require "rails_helper"

RSpec.describe "Jobs de criação de pagamento", type: :job do
  describe CreateUser::BoletoPaymentJob do
    it "cria boleto, resgata cupom quando informado e envia e-mail" do
      company = create(:company)
      result = Cmd::MercadoPago::CreateBoletoPayment::Result.new(true, { company: company }, nil)
      command = instance_double(Cmd::MercadoPago::CreateBoletoPayment, call: result)
      mail = instance_double(ActionMailer::MessageDelivery, deliver_later: true)

      allow(Cmd::MercadoPago::CreateBoletoPayment).to receive(:new).with(company, amount_override: 90).and_return(command)
      allow(Payments::BoletoMailer).to receive(:with).with(result.mailer_params).and_return(double(ticket_email: mail))
      allow(Coupons::Redeem).to receive(:call)
      allow(Coupon).to receive(:find).with("coupon-id").and_return(double("Coupon"))
      allow(company).to receive(:current_subscription).and_return(double("Subscription"))
      allow(Company).to receive(:find_by).with(id: company.id).and_return(company)

      described_class.new.perform(company.id, coupon_id: "coupon-id", original_amount: 100, final_amount: 90)

      aggregate_failures do
        expect(mail).to have_received(:deliver_later)
        expect(Coupons::Redeem).to have_received(:call).with(hash_including(company: company, original_amount: 100, final_amount: 90))
      end
    end
  end

  describe CreateUser::PixPaymentJob do
    it "cria pix e envia e-mail" do
      company = create(:company)
      result = Cmd::MercadoPago::CreatePixPayment::Result.new(true, { company: company }, nil)
      command = instance_double(Cmd::MercadoPago::CreatePixPayment, call: result)
      mail = instance_double(ActionMailer::MessageDelivery, deliver_later: true)

      allow(Cmd::MercadoPago::CreatePixPayment).to receive(:new).with(company, amount_override: nil).and_return(command)
      allow(Payments::PixMailer).to receive(:with).with(result.mailer_params).and_return(double(pix_email: mail))

      described_class.new.perform(company.id)

      expect(mail).to have_received(:deliver_later)
    end
  end

  describe CreateUser::CreditCardPaymentJob do
    it "chama command de cartão quando empresa existe" do
      company = create(:company)
      command = instance_double(Cmd::MercadoPago::CreateCreditCardPayment, call: true)

      allow(Cmd::MercadoPago::CreateCreditCardPayment).to receive(:new).with(company, "token").and_return(command)

      described_class.new.perform(company.id, "token")

      expect(command).to have_received(:call)
    end

    it "registra erro quando empresa não existe" do
      allow(Rails.logger).to receive(:error)

      described_class.new.perform(SecureRandom.uuid, "token")

      expect(Rails.logger).to have_received(:error).with(/Company with id .* not found\./)
    end
  end
end
