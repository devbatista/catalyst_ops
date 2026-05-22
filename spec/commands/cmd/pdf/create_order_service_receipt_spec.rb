require "rails_helper"

RSpec.describe Cmd::Pdf::CreateOrderServiceReceipt do
  describe "#generate_pdf_data" do
    it "gera PDF de recebimento com itens recebidos" do
      order_service = order_service_with_received_item

      pdf_data = described_class.new(order_service, kind: :recebimento, generated_by: build(:user, name: "Gestor")).generate_pdf_data

      expect(pdf_data).to start_with("%PDF")
      expect(pdf_data.bytesize).to be > 1_000
    end

    it "gera PDF de devolução" do
      order_service = order_service_with_received_item

      pdf_data = described_class.new(order_service, kind: :devolucao).generate_pdf_data

      expect(pdf_data).to start_with("%PDF")
    end

    it "gera PDF mesmo sem itens recebidos" do
      order_service = create_order_service

      pdf_data = described_class.new(order_service, kind: :recebimento).generate_pdf_data

      expect(pdf_data).to start_with("%PDF")
    end

    it "rejeita tipo inválido" do
      expect do
        described_class.new(create_order_service, kind: :outro).generate_pdf_data
      end.to raise_error(ArgumentError, "Tipo de comprovante inválido")
    end
  end

  describe "#filename" do
    it "usa prefixo de recebimento" do
      order_service = build(:order_service)
      order_service.code = 123
      command = described_class.new(order_service, kind: :recebimento)

      expect(command.filename).to eq("comprovante_recebimento_os_123.pdf")
    end

    it "usa prefixo de devolução" do
      order_service = build(:order_service)
      order_service.code = 123
      command = described_class.new(order_service, kind: :devolucao)

      expect(command.filename).to eq("comprovante_devolucao_os_123.pdf")
    end
  end

  def create_order_service
    plan = create(:plan, max_orders: 10)
    company = create(:company, plan: plan)
    create(:subscription, company: company, subscription_plan: plan)
    client = create(:client, company: company)
    create(:order_service, client: client, company: company)
  end

  def order_service_with_received_item
    order_service = create_order_service
    create(:order_service_received_item, order_service: order_service)
    order_service.reload
  end
end
