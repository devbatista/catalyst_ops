require "rails_helper"
require "cancan/matchers"

RSpec.describe Ability, type: :model do
  subject(:ability) { Ability.new(user) }

  let(:client) { create(:client) }
  let(:order_service) { create(:order_service) }
  let(:assignment) { create(:assignment) }
  let(:service_item) { create(:service_item, order_service: order_service) }
  let(:gestor) { create(:user, role: "gestor") }
  let(:tecnico) { create(:user, role: "tecnico") }
  let(:admin) { create(:user, role: "admin") }
  let(:other_user) { create(:user, role: "tecnico") }

  context "quando admin" do
    let(:user) { admin }

    it { is_expected.to be_able_to(:manage, :all) }
  end

  context "quando gestor" do
    let(:user) { gestor }

    it { is_expected.to be_able_to(:manage, Client) }
    it { is_expected.to be_able_to(:manage, OrderService) }
    it { is_expected.to be_able_to(:manage, Assignment) }
    it { is_expected.to be_able_to(:manage, ServiceItem) }
    it { is_expected.to be_able_to(:read, User.new(role: "tecnico")) }
    it { is_expected.to be_able_to(:read, :dashboard) }

    it "pode ler e atualizar o próprio perfil" do
      expect(ability).to be_able_to(:read, gestor)
      expect(ability).to be_able_to(:update, gestor)
    end

    it "não pode atualizar perfil de outro usuário" do
      expect(ability).not_to be_able_to(:update, other_user)
    end
  end

  context "quando técnico" do
    let(:user) { tecnico }
    let(:order_service) { create(:order_service) }

    before do
      # Associa o técnico à OS
      order_service.users << tecnico
    end

    it "pode ler OS atribuída a ele" do
      expect(ability).to be_able_to(:read, order_service)
    end

    it "não pode ler OS não atribuída" do
      os = create(:order_service)
      expect(ability).not_to be_able_to(:read, os)
    end

    it "pode atualizar OS atribuída e não concluída" do
      allow(order_service).to receive(:concluida?).and_return(false)
      expect(ability).to be_able_to(:update, order_service)
    end

    it "não pode atualizar OS atribuída e já concluída" do
      allow(order_service).to receive(:concluida?).and_return(true)
      expect(ability).not_to be_able_to(:update, order_service)
    end

    it "pode gerenciar itens de serviço das suas OSs" do
      service_item = create(:service_item, order_service: order_service)
      expect(ability).to be_able_to(:manage, service_item)
    end

    it "não pode gerenciar itens de serviço de OSs não atribuídas" do
      other_os = create(:order_service)
      other_item = create(:service_item, order_service: other_os)
      expect(ability).not_to be_able_to(:manage, other_item)
    end

    it "pode ler próprias atribuições" do
      assignment = create(:assignment,
                          user: tecnico,
                          order_service: create(:order_service,
                                                scheduled_at: 2.days.from_now))
      expect(ability).to be_able_to(:read, assignment)
    end

    it "não pode ler atribuições de outros" do
      assignment = create(:assignment, user: other_user)
      expect(ability).not_to be_able_to(:read, assignment)
    end

    it "pode ler e atualizar o próprio perfil" do
      expect(ability).to be_able_to(:read, tecnico)
      expect(ability).to be_able_to(:update, tecnico)
    end

    it "não pode atualizar perfil de outro usuário" do
      expect(ability).not_to be_able_to(:update, other_user)
    end

    it "pode ler clientes das suas OSs" do
      client = order_service.client
      expect(ability).to be_able_to(:read, client)
    end

    it "não pode ler clientes de OSs não atribuídas" do
      other_client = create(:client)
      expect(ability).not_to be_able_to(:read, other_client)
    end

    it { is_expected.to be_able_to(:read, :dashboard) }
  end

  context "quando guest (não logado)" do
    let(:user) { nil }

    it { is_expected.not_to be_able_to(:manage, :all) }
    it { is_expected.not_to be_able_to(:read, Client) }
    it { is_expected.not_to be_able_to(:read, OrderService) }
    it { is_expected.not_to be_able_to(:read, Assignment) }
    it { is_expected.not_to be_able_to(:read, ServiceItem) }
    it { is_expected.not_to be_able_to(:read, :dashboard) }
  end
end
