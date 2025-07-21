require "rails_helper"

RSpec.describe OrderService, type: :model do
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
    let!(:os_agendada) { create(:order_service, status: :agendada) }
    let!(:os_andamento) { create(:order_service, status: :em_andamento) }
    let!(:os_concluida) { create(:order_service, status: :concluida) }
    let!(:os_cancelada) { create(:order_service, status: :cancelada) }

    it "by_status retorna ordens pelo status" do
      expect(OrderService.by_status(:agendada)).to include(os_agendada)
      expect(OrderService.by_status(:em_andamento)).to include(os_andamento)
      expect(OrderService.by_status(:concluida)).to include(os_concluida)
      expect(OrderService.by_status(:cancelada)).to include(os_cancelada)
    end
  end

  describe "métodos de negócio" do
    let(:order_service) { create(:order_service, status: :agendada) }

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
      expect(order_service.total_value).to eq(200.0)
    end

    it "formata o valor total" do
      create(:service_item, order_service: order_service, quantity: 2, unit_price: 50.0)
      expect(order_service.formatted_total_value).to eq("R$ 100.00")
    end
  end

  describe "factory" do
    it "possui uma factory válida" do
      expect(build(:order_service)).to be_valid
    end
  end
end