require "rails_helper"

RSpec.describe User, type: :model do
  describe "validações" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(100) }
    it { should validate_presence_of(:role) }
    it { should allow_value("email@dominio.com").for(:email) }
    it { should_not allow_value("email_invalido").for(:email) }
  end

  describe "associações" do
    it { should have_many(:assignments).dependent(:destroy) }
    it { should have_many(:order_services).through(:assignments) }
  end

  describe "scopes" do
    let!(:tecnico) { create(:user, role: :tecnico) }
    let!(:gestor) { create(:user, role: :gestor) }
    let!(:admin) { create(:user, role: :admin) }

    it ".tecnicos retorna apenas técnicos" do
      expect(User.tecnicos).to include(tecnico)
      expect(User.tecnicos).not_to include(gestor, admin)
    end

    it ".gestores retorna apenas gestores" do
      expect(User.gestores).to include(gestor)
      expect(User.gestores).not_to include(tecnico, admin)
    end
  end

  describe "métodos de negócio" do
    let(:tecnico) { create(:user, role: :tecnico, name: "joão da silva") }
    let(:admin) { create(:user, role: :admin) }
    let(:gestor) { create(:user, role: :gestor) }

    it "#can_be_assigned_to_orders? retorna true para técnico" do
      expect(tecnico.can_be_assigned_to_orders?).to be true
      expect(admin.can_be_assigned_to_orders?).to be false
    end

    it "#full_name retorna nome capitalizado" do
      expect(tecnico.full_name).to eq("João Da Silva")
    end

    it "#orders_count retorna o número de OS" do
      os1 = create(:order_service, scheduled_at: 1.day.from_now)
      os2 = create(:order_service, scheduled_at: 2.days.from_now)
      create(:assignment, user: tecnico, order_service: os1)
      create(:assignment, user: tecnico, order_service: os2)
      expect(tecnico.orders_count).to eq(2)
    end

    it "#pending_orders_count retorna o número de OS agendadas" do
      os1 = create(:order_service, status: :agendada, scheduled_at: 1.day.from_now)
      os2 = create(:order_service, status: :concluida, scheduled_at: 2.days.from_now)
      create(:assignment, user: tecnico, order_service: os1)
      create(:assignment, user: tecnico, order_service: os2)
      expect(tecnico.pending_orders_count).to eq(1)
    end

    it "#completed_orders_count retorna o número de OS concluídas" do
      os1 = create(:order_service, status: :concluida)
      os2 = create(:order_service, status: :agendada)
      create(:assignment, user: tecnico, order_service: os1)
      create(:assignment, user: tecnico, order_service: os2)
      expect(tecnico.completed_orders_count).to eq(1)
    end

    it "#can_manage_clients? retorna true para admin e gestor" do
      expect(admin.can_manage_clients?).to be true
      expect(gestor.can_manage_clients?).to be true
      expect(tecnico.can_manage_clients?).to be false
    end

    it "#can_create_orders? retorna true para admin e gestor" do
      expect(admin.can_create_orders?).to be true
      expect(gestor.can_create_orders?).to be true
      expect(tecnico.can_create_orders?).to be false
    end
  end

  describe "callbacks" do
    it "normaliza o nome antes de validar" do
      user = build(:user, name: "  maria da silva  ")
      user.valid?
      expect(user.name).to eq("Maria Da Silva")
    end

    it "não envia e-mail de boas-vindas se não persistido" do
      user = build(:user)
      expect(user).not_to receive(:send_welcome_email)
      user.valid?
    end

    it "envia e-mail de boas-vindas após criar (stub)" do
      user = build(:user)
      allow(user).to receive(:send_welcome_email)
      user.save
      expect(user).to have_received(:send_welcome_email)
    end
  end

  describe "factory" do
    it "possui uma factory válida" do
      expect(build(:user)).to be_valid
    end
  end
end
