require "rails_helper"

RSpec.describe Cmd::Budgets::ApproveAndCreateOrderService do
  subject(:command) { described_class.new(budget: budget, approver_role: "gestor") }

  let(:company) { company_with_active_subscription }
  let(:client) { create(:client, company: company) }
  let(:budget) { create(:budget, company: company, client: client, status: :enviado) }
  let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    allow(BudgetMailer).to receive(:notify_manager_order_service_created).and_return(mail_delivery)
    allow(Audit::Log).to receive(:call)
  end

  describe "#call" do
    it "aprova o orçamento e cria uma OS vinculada" do
      order_service = nil
      budget

      expect do
        order_service = command.call
      end.to change(OrderService, :count).by(1)
        .and change(ServiceItem, :count).by(1)

      budget.reload

      aggregate_failures do
        expect(order_service).to eq(budget.order_service)
        expect(budget).to be_aprovado
        expect(budget.approved_at).to be_present
        expect(order_service).to be_pendente
        expect(order_service.company).to eq(company)
        expect(order_service.client).to eq(client)
        expect(order_service.reload.service_items.first.description).to eq(budget.service_items.first.description)
        expect(BudgetMailer).to have_received(:notify_manager_order_service_created).with(
          budget,
          order_service,
          approver_role: "gestor"
        )
      end
    end

    it "é idempotente quando o orçamento já tem OS vinculada" do
      existing_order_service = create(:order_service, company: company, client: client)
      budget.update_columns(order_service_id: existing_order_service.id)

      expect do
        result = command.call
        expect(result).to eq(existing_order_service)
      end.not_to change(OrderService, :count)

      expect(BudgetMailer).not_to have_received(:notify_manager_order_service_created)
    end

    it "usa texto padrão quando título ou descrição são curtos para a OS" do
      budget.update!(title: "ABC", description: "abc")

      order_service = command.call

      aggregate_failures do
        expect(order_service.title).to eq("Orçamento ##{budget.code}")
        expect(order_service.description).to eq("Criada automaticamente a partir do orçamento ##{budget.code}.")
      end
    end

    it "mantém o orçamento sem vínculo quando a criação da OS falha" do
      allow(OrderService).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

      expect do
        command.call
      end.to raise_error(ActiveRecord::RecordInvalid)

      aggregate_failures do
        expect(budget.reload).to be_enviado
        expect(budget.order_service).to be_nil
      end
    end
  end

  def company_with_active_subscription
    plan = create(:plan)
    company = create(:company, plan: plan)
    create(:subscription, company: company, subscription_plan: plan, status: :active)
    company
  end
end
