require "rails_helper"

RSpec.describe OrderService, type: :model do
  subject(:order_service_model) { build(:order_service, company: company, client: client) }

  let(:company) { company_with_active_subscription }
  let(:client) { create(:client, company: company) }
  let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    allow(OrderServiceMailer).to receive(:notify_client_on_complete).and_return(mail_delivery)
    allow(OrderServiceMailer).to receive(:notify_manager_on_complete).and_return(mail_delivery)
    allow(OrderServiceMailer).to receive(:notify_client_on_scheduled).and_return(mail_delivery)
    allow(OrderServiceMailer).to receive(:notify_technical_on_scheduled).and_return(mail_delivery)
    allow(OrderServiceMailer).to receive(:notify_client_on_finished).and_return(mail_delivery)
    allow(OrderServiceMailer).to receive(:notify_technician_on_finished).and_return(mail_delivery)
    allow(OrderServiceMailer).to receive(:notify_in_progress).and_return(mail_delivery)
    allow(OrderServiceMailer).to receive(:notify_overdue).and_return(mail_delivery)
    allow(UserMailer).to receive(:welcome_email).and_return(mail_delivery)
  end

  describe "validações" do
    it { should belong_to(:client) }
    it { should have_many(:assignments).dependent(:destroy) }
    it { should have_many(:users).through(:assignments) }
    it { should have_many(:service_items).dependent(:destroy) }

    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:scheduled_at) }
    it { should validate_presence_of(:client_id) }
  end

  describe "escopos" do
    let!(:os_agendada) { create_order_service(status: :agendada) }
    let!(:os_andamento) { create_order_service(status: :em_andamento, users: [create(:user, :tecnico, company: company, active: true)]) }
    let!(:os_concluida) { create_order_service(status: :concluida) }
    let!(:os_cancelada) { create_order_service(status: :cancelada) }

    it "by_status retorna ordens pelo status" do
      expect(OrderService.by_status(:agendada)).to include(os_agendada)
      expect(OrderService.by_status(:em_andamento)).to include(os_andamento)
      expect(OrderService.by_status(:concluida)).to include(os_concluida)
      expect(OrderService.by_status(:cancelada)).to include(os_cancelada)
    end

    it "retorna ordens por cliente, técnico, atribuição e orçamento" do
      technician = os_andamento.users.first
      without_budget = create_order_service(status: :agendada, created_without_budget: true)

      aggregate_failures do
        expect(OrderService.by_client(client.id)).to include(os_agendada, os_andamento)
        expect(OrderService.by_technician(technician.id)).to contain_exactly(os_andamento)
        expect(OrderService.assigned).to contain_exactly(os_andamento)
        expect(OrderService.unassigned).to include(os_agendada, os_concluida, os_cancelada, without_budget)
        expect(OrderService.created_without_budget).to contain_exactly(without_budget)
      end
    end

    it "retorna ordens agendadas para hoje, atrasadas e finalizadas no mês" do
      travel_to Time.zone.local(2026, 5, 15, 8, 0, 0) do
        today = create_order_service(status: :agendada, scheduled_at: Time.current.change(hour: 10), expected_end_at: Time.current.change(hour: 12))
        overdue = create_order_service(status: :agendada)
        overdue.update_columns(scheduled_at: 2.days.ago, expected_end_at: 1.day.ago)
        finished = create_order_service(status: :finalizada, updated_at: Time.current)
        old_finished = create_order_service(status: :finalizada)
        old_finished.update_column(:updated_at, 2.months.ago)

        aggregate_failures do
          expect(OrderService.scheduled_for_today).to include(today)
          expect(OrderService.to_overdue).to include(overdue)
          expect(OrderService.finished_this_month).to include(finished)
        end
      end
    end
  end

  describe "métodos de negócio" do
    let(:order_service) { create_order_service(status: :agendada) }

    it "concluida? retorna true se status for concluída" do
      order_service.update(status: :concluida)
      expect(order_service.concluida?).to be true
    end

    it "cancelada? retorna true se status for cancelada" do
      order_service.update(status: :cancelada)
      expect(order_service.cancelada?).to be true
    end

    it "can_assign_technician? retorna true para OS ativa" do
      expect(order_service.can_assign_technician?).to be true
    end

    it "can_assign_technician? retorna false para OS concluída" do
      order_service.update(status: :concluida)
      expect(order_service.can_assign_technician?).to be false
    end

    it "retorna o valor total dos itens de serviço" do
      item1 = create(:service_item, order_service: order_service, quantity: 2, unit_price: 50.0)
      item2 = create(:service_item, order_service: order_service, quantity: 1, unit_price: 100.0)
      expect(order_service.reload.total_value).to eq(200.0)
    end

    it "formata o valor total" do
      create(:service_item, order_service: order_service, quantity: 2, unit_price: 50.0)
      expect(order_service.reload.formatted_total_value).to eq("R$ 100.00")
    end

    it "calcula percentual de progresso por status" do
      expect(build(:order_service, status: :pendente).progress_percentage).to eq(0)
      expect(build(:order_service, status: :agendada).progress_percentage).to eq(25)
      expect(build(:order_service, status: :em_andamento).progress_percentage).to eq(50)
      expect(build(:order_service, status: :concluida).progress_percentage).to eq(90)
      expect(build(:order_service, status: :finalizada).progress_percentage).to eq(100)
    end

    it "retorna cor por status" do
      expect(build(:order_service, status: :pendente).status_color).to eq("secondary")
      expect(build(:order_service, status: :atrasada).status_color).to eq("dark")
      expect(build(:order_service, status: :cancelada).status_color).to eq("danger")
    end

    it "retorna ações disponíveis para status agendado" do
      order_service = build(:order_service, status: :agendada)

      expect(order_service.available_actions).to contain_exactly(
        { label: "Iniciar", target_status: :em_andamento },
        { label: "Cancelar", target_status: :cancelada }
      )
    end

    it "retorna próximas transições para todos os status" do
      expectations = {
        pendente: ["cancelada"],
        agendada: ["em_andamento", "cancelada"],
        atrasada: ["em_andamento", "cancelada"],
        em_andamento: ["concluida", "cancelada"],
        concluida: ["finalizada"],
        finalizada: [],
        cancelada: []
      }

      expectations.each do |status, next_statuses|
        expect(build(:order_service, status: status).next_possible_statuses).to eq(next_statuses)
      end
    end

    it "retorna permissões de ação conforme status e conteúdo" do
      technician = create(:user, :tecnico, company: company, active: true)
      another_technician = create(:user, :tecnico, company: company, active: true)
      scheduled = create_order_service(status: :agendada)
      scheduled.users << technician
      in_progress = create_order_service(status: :em_andamento, users: [another_technician])
      create(:service_item, order_service: in_progress)

      aggregate_failures do
        expect(scheduled.reload.can_be_started?).to be true
        expect(in_progress.reload.can_be_completed?).to be true
        expect(build(:order_service, status: :concluida).can_be_cancelled?).to be false
        expect(build(:order_service, status: :atrasada).overdue?).to be true
      end
    end

    it "calcula duração em horas" do
      order_service = build(:order_service, started_at: Time.zone.local(2026, 5, 20, 8), finished_at: Time.zone.local(2026, 5, 20, 10, 30))

      expect(order_service.duration_in_hours).to eq(2.5)
    end

    it "define código sequencial por empresa" do
      create(:order_service, company: company, client: client, code: 1)

      order_service = create(:order_service, company: company, client: client, code: nil)

      expect(order_service.code).to eq(2)
    end

    it "preenche timestamps automáticos ao mudar status" do
      order_service = create_order_service(status: :agendada)
      create(:assignment, order_service: order_service, user: create(:user, :tecnico, company: order_service.company, active: true))

      order_service.update!(status: :em_andamento)
      order_service.update!(status: :concluida)

      aggregate_failures do
        expect(order_service.started_at).to be_present
        expect(order_service.finished_at).to be_present
      end
    end

    it "respeita limite de ordens pelo plano" do
      plan = create(:plan, max_orders: 1)
      company = create(:company, plan: plan)
      create(:subscription, company: company, subscription_plan: plan, status: :active)
      client = create(:client, company: company)
      create(:order_service, company: company, client: client)

      order_service = build(:order_service, company: company, client: client)

      aggregate_failures do
        expect(order_service).not_to be_valid
        expect(order_service.errors[:base]).to include("Limite de ordens de serviço atingido para o plano atual da empresa.")
      end
    end

    it "valida desconto percentual e exige motivo quando desconto é aplicado" do
      order_service = build(:order_service, company: company, client: client, discount_type: "percent", discount_value: 101, discount_reason: "")
      order_service.service_items.build(description: "Servico", quantity: 1, unit_price: 100)

      aggregate_failures do
        expect(order_service).not_to be_valid
        expect(order_service.errors[:discount_value]).to include("não pode ser maior que 100%")
        expect(order_service.errors[:discount_reason]).to include("deve ser informado quando houver desconto")
      end
    end

    it "valida desconto fixo maior que subtotal" do
      order_service = build(:order_service, company: company, client: client, discount_type: "fixed", discount_value: 150, discount_reason: "Cortesia")
      order_service.service_items.build(description: "Servico", quantity: 1, unit_price: 100)

      aggregate_failures do
        expect(order_service).not_to be_valid
        expect(order_service.errors[:discount_value]).to include("não pode ser maior que o subtotal da OS")
      end
    end

    it "normaliza desconto vazio para nenhum desconto" do
      order_service = create_order_service(discount_type: "", discount_value: 50, discount_reason: "Promoção")

      aggregate_failures do
        expect(order_service.discount_type).to eq("none")
        expect(order_service.discount_value).to eq(0)
        expect(order_service.discount_reason).to be_nil
      end
    end
  end

  describe "factory" do
    it "possui uma factory válida" do
      expect(build(:order_service, company: company, client: client)).to be_valid
    end
  end

  def company_with_active_subscription
    plan = create(:plan)
    company = create(:company, plan: plan)
    create(:subscription, company: company, subscription_plan: plan, status: :active)
    company
  end

  def create_order_service(attributes = {})
    users = attributes.delete(:users)
    order_service = build(:order_service, { company: company, client: client }.merge(attributes))
    order_service.users = users if users
    order_service.save!
    order_service
  end
end
