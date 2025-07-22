require "rails_helper"

RSpec.describe Assignment, type: :model do
  describe "validações" do
    subject { create(:assignment) }
    it { should belong_to(:user) }
    it { should belong_to(:order_service) }

    it "não permite o mesmo usuário na mesma OS" do
      user = create(:user, role: "tecnico")
      os = create(:order_service)
      create(:assignment, user: user, order_service: os)
      assignment = build(:assignment, user: user, order_service: os)
      expect(assignment).not_to be_valid
      expect(assignment.errors[:user_id]).to include("já está atribuído a esta OS")
    end

    context "quando o usuário não é técnico" do
      it "não permite atribuição" do
        user = create(:user, role: "gestor")
        os = create(:order_service)
        assignment = build(:assignment, user: user, order_service: os)
        expect(assignment).not_to be_valid
        expect(assignment.errors[:user]).to include("deve ser um técnico")
      end
    end

    context "quando a OS não permite mais atribuições" do
      it "não permite atribuição" do
        user = create(:user, role: "tecnico")
        os = create(:order_service)
        allow(os).to receive(:can_assign_technician?).and_return(false)
        assignment = build(:assignment, user: user, order_service: os)
        expect(assignment).not_to be_valid
        expect(assignment.errors[:order_service]).to include("não permite mais atribuições")
      end
    end

    context "quando o técnico já tem outra OS agendada para o mesmo dia" do
      it "não permite atribuição" do
        user = create(:user, role: "tecnico")
        date = 2.days.from_now
        os1 = create(:order_service, scheduled_at: date)
        os2 = create(:order_service, scheduled_at: date)
        create(:assignment, user: user, order_service: os1)
        assignment = build(:assignment, user: user, order_service: os2)
        expect(assignment).not_to be_valid
        expect(assignment.errors[:user]).to include("já possui outra OS agendada para este dia")
      end

      it "permite atribuição se a OS anterior estiver concluída" do
        user = create(:user, role: "tecnico")
        date = 2.days.from_now
        os1 = create(:order_service, scheduled_at: date, status: :concluida)
        os2 = create(:order_service, scheduled_at: date)
        create(:assignment, user: user, order_service: os1)
        assignment = build(:assignment, user: user, order_service: os2)
        expect(assignment).to be_valid
      end

      it "permite atribuição se a OS anterior estiver cancelada" do
        user = create(:user, role: "tecnico")
        date = 2.days.from_now
        os1 = create(:order_service, scheduled_at: date, status: :cancelada)
        os2 = create(:order_service, scheduled_at: date)
        create(:assignment, user: user, order_service: os1)
        assignment = build(:assignment, user: user, order_service: os2)
        expect(assignment).to be_valid
      end
    end
  end

  describe "escopos" do
    let(:user) { create(:user, role: "tecnico") }

    let!(:os_concluida) do
      os = create(:order_service, status: :concluida)
      create(:assignment, user: user, order_service: os)
      os
    end
    let!(:a2) { Assignment.find_by(user: user, order_service: os_concluida) }

    let!(:os_ativa) { create(:order_service, status: :agendada) }
    let!(:a1) { create(:assignment, user: user, order_service: os_ativa) }

    it "active retorna apenas assignments de OSs ativas" do
      expect(Assignment.active).to include(a1)
      expect(Assignment.active).not_to include(a2)
    end

    it "by_technician retorna assignments do técnico" do
      expect(Assignment.by_technician(user.id)).to include(a1, a2)
    end

    it "by_status retorna assignments pela OS" do
      expect(Assignment.by_status(:agendada)).to include(a1)
      expect(Assignment.by_status(:concluida)).to include(a2)
    end
  end

  describe "métodos de negócio" do
    it "can_be_removed? retorna true se OS não estiver concluída" do
      assignment = build(:assignment, order_service: build(:order_service, status: :agendada))
      expect(assignment.can_be_removed?).to be true
    end

    it "can_be_removed? retorna false se OS estiver concluída" do
      assignment = build(:assignment, order_service: build(:order_service, status: :concluida))
      expect(assignment.can_be_removed?).to be false
    end
  end

  describe "callbacks" do
    it "chama notify_technician após criar" do
      assignment = build(:assignment)
      expect(assignment).to receive(:notify_technician)
      assignment.save(validate: false)
      # O método está comentado, então só testamos se é chamado
    end

    it "chama notify_technician_removal após destruir" do
      assignment = create(:assignment)
      expect(assignment).to receive(:notify_technician_removal)
      assignment.destroy
      # O método está comentado, então só testamos se é chamado
    end
  end

  describe "factory" do
    it "possui uma factory válida" do
      expect(build(:assignment)).to be_valid
    end
  end
end
