require "rails_helper"

RSpec.describe SupportTicket, type: :model do
  describe "associações" do
    it { is_expected.to belong_to(:company) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:order_service).optional }
    it { is_expected.to belong_to(:assigned_to).class_name("User").optional }
    it { is_expected.to have_many(:support_messages).dependent(:destroy) }
  end

  describe "validações" do
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_length_of(:subject).is_at_most(200) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:impact) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:priority) }
  end

  describe "enums" do
    it "define as categorias esperadas" do
      expect(described_class.categories).to include(
        "duvida" => 0,
        "problema_tecnico" => 1,
        "financeiro" => 2,
        "sugestao" => 3,
        "outros" => 4
      )
    end

    it "define os impactos esperados" do
      expect(described_class.impacts).to include(
        "baixo" => 0,
        "medio" => 1,
        "alto" => 2,
        "bloqueante" => 3
      )
    end

    it "define os status esperados" do
      expect(described_class.statuses).to include(
        "aberto" => 0,
        "em_andamento" => 1,
        "aguardando_cliente" => 2,
        "resolvido" => 3,
        "fechado" => 4,
        "cancelado" => 5
      )
    end

    it "define as prioridades esperadas" do
      expect(described_class.priorities).to include(
        "baixa" => 0,
        "normal" => 1,
        "alta" => 2,
        "critica" => 3
      )
    end
  end

  describe "scopes" do
    describe ".recent" do
      it "ordena por última resposta e depois por criação" do
        old_ticket = create(:support_ticket)
        middle_ticket = create(:support_ticket)
        recent_ticket = create(:support_ticket)

        old_ticket.update_columns(last_reply_at: 3.days.ago, created_at: 3.days.ago)
        middle_ticket.update_columns(last_reply_at: 2.days.ago, created_at: 2.days.ago)
        recent_ticket.update_columns(last_reply_at: 1.day.ago, created_at: 1.day.ago)

        expect(described_class.where(id: [old_ticket.id, middle_ticket.id, recent_ticket.id]).recent).to eq(
          [recent_ticket, middle_ticket, old_ticket]
        )
      end
    end

    describe ".by_company" do
      it "retorna apenas tickets da empresa informada" do
        company = create(:company)
        other_company = create(:company)
        ticket = create(:support_ticket, company: company)
        other_ticket = create(:support_ticket, company: other_company)

        result = described_class.where(id: [ticket.id, other_ticket.id]).by_company(company.id)

        expect(result).to contain_exactly(ticket)
      end
    end

    describe ".open_status" do
      it "retorna apenas tickets em status abertos para atendimento" do
        open_ticket = create(:support_ticket, status: :aberto)
        in_progress_ticket = create(:support_ticket, status: :em_andamento)
        waiting_ticket = create(:support_ticket, status: :aguardando_cliente)
        resolved_ticket = create(:support_ticket, status: :resolvido)
        closed_ticket = create(:support_ticket, status: :fechado)

        result = described_class.where(
          id: [
            open_ticket.id,
            in_progress_ticket.id,
            waiting_ticket.id,
            resolved_ticket.id,
            closed_ticket.id
          ]
        ).open_status

        expect(result).to contain_exactly(open_ticket, in_progress_ticket, waiting_ticket)
      end
    end

    describe ".recent_first" do
      it "usa a mesma ordenação de tickets recentes" do
        old_ticket = create(:support_ticket)
        recent_ticket = create(:support_ticket)
        old_ticket.update_columns(last_reply_at: 2.days.ago, created_at: 2.days.ago)
        recent_ticket.update_columns(last_reply_at: 1.day.ago, created_at: 1.day.ago)

        expect(described_class.where(id: [old_ticket.id, recent_ticket.id]).recent_first).to eq(
          [recent_ticket, old_ticket]
        )
      end
    end
  end

  describe "callbacks" do
    it "preenche last_reply_at ao criar o ticket" do
      reference_time = Time.zone.local(2026, 5, 17, 10, 0, 0)
      allow(Time).to receive(:current).and_return(reference_time)

      ticket = create(:support_ticket, last_reply_at: nil)

      expect(ticket.last_reply_at).to eq(reference_time)
    end

    it "mantém last_reply_at informado na criação" do
      custom_time = Time.zone.local(2026, 5, 16, 9, 0, 0)

      ticket = create(:support_ticket, last_reply_at: custom_time)

      expect(ticket.last_reply_at).to eq(custom_time)
    end

    it "bloqueia mudança de status depois de fechado" do
      ticket = create(:support_ticket, status: :fechado)

      expect(ticket.update(status: :em_andamento)).to be(false)
      expect(ticket.errors[:status]).to include("Não pode ser alterado em tickets fechado ou cancelado")
    end

    it "bloqueia mudança de status depois de cancelado" do
      ticket = create(:support_ticket, status: :cancelado)

      expect(ticket.update(status: :aberto)).to be(false)
      expect(ticket.errors[:status]).to include("Não pode ser alterado em tickets fechado ou cancelado")
    end
  end

  describe "#mark_as_resolved!" do
    it "marca o ticket como resolvido" do
      ticket = create(:support_ticket, status: :em_andamento)

      ticket.mark_as_resolved!

      expect(ticket.reload).to be_resolvido
    end
  end

  describe "#mark_as_closed!" do
    it "marca o ticket como fechado" do
      ticket = create(:support_ticket, status: :resolvido)

      ticket.mark_as_closed!

      expect(ticket.reload).to be_fechado
    end
  end

  describe "#add_message!" do
    it "cria mensagem no ticket" do
      ticket = create(:support_ticket)
      user = create(:user, :gestor, company: ticket.company, active: true)

      message = ticket.add_message!(user: user, body: "Preciso de ajuda.")

      aggregate_failures do
        expect(message).to be_persisted
        expect(message.body).to eq("Preciso de ajuda.")
        expect(message.user).to eq(user)
        expect(ticket.support_messages).to contain_exactly(message)
      end
    end

    it "muda para aguardando cliente quando admin responde ticket aberto" do
      ticket = create(:support_ticket, status: :aberto)
      admin = create(:user, :admin, active: true)

      ticket.add_message!(user: admin, body: "Pode testar novamente?")

      expect(ticket.reload).to be_aguardando_cliente
    end

    it "muda para aguardando cliente quando admin responde ticket em andamento" do
      ticket = create(:support_ticket, status: :em_andamento)
      admin = create(:user, :admin, active: true)

      ticket.add_message!(user: admin, body: "Enviei uma correção.")

      expect(ticket.reload).to be_aguardando_cliente
    end

    it "mantém status aguardando cliente quando admin responde novamente" do
      ticket = create(:support_ticket, status: :aguardando_cliente)
      admin = create(:user, :admin, active: true)

      ticket.add_message!(user: admin, body: "Complementando a resposta.")

      expect(ticket.reload).to be_aguardando_cliente
    end

    it "atribui o ticket ao admin quando ainda não existe responsável" do
      ticket = create(:support_ticket, assigned_to: nil)
      admin = create(:user, :admin, active: true)

      ticket.add_message!(user: admin, body: "Vou cuidar deste ticket.")

      expect(ticket.reload.assigned_to).to eq(admin)
    end

    it "não troca responsável quando o ticket já está atribuído" do
      first_admin = create(:user, :admin, active: true)
      second_admin = create(:user, :admin, active: true)
      ticket = create(:support_ticket, assigned_to: first_admin)

      ticket.add_message!(user: second_admin, body: "Vou acompanhar.")

      expect(ticket.reload.assigned_to).to eq(first_admin)
    end

    it "muda para em andamento quando cliente responde ticket aberto" do
      ticket = create(:support_ticket, status: :aberto)
      user = create(:user, :gestor, company: ticket.company, active: true)

      ticket.add_message!(user: user, body: "Segue mais detalhe.")

      expect(ticket.reload).to be_em_andamento
    end

    it "muda para em andamento quando cliente responde ticket aguardando cliente" do
      ticket = create(:support_ticket, status: :aguardando_cliente)
      user = create(:user, :gestor, company: ticket.company, active: true)

      ticket.add_message!(user: user, body: "Respondi a pergunta.")

      expect(ticket.reload).to be_em_andamento
    end

    it "reabre ticket resolvido quando cliente responde" do
      ticket = create(:support_ticket, status: :resolvido)
      user = create(:user, :gestor, company: ticket.company, active: true)

      ticket.add_message!(user: user, body: "O problema voltou.")

      expect(ticket.reload).to be_em_andamento
    end

    it "não permite adicionar mensagem em ticket fechado" do
      ticket = create(:support_ticket, status: :fechado)
      user = create(:user, :gestor, company: ticket.company, active: true)

      expect { ticket.add_message!(user: user, body: "Ainda preciso de ajuda.") }
        .to raise_error(RuntimeError, /Ticket fechado ou cancelado/)
    end

    it "não permite adicionar mensagem em ticket cancelado" do
      ticket = create(:support_ticket, status: :cancelado)
      user = create(:user, :gestor, company: ticket.company, active: true)

      expect { ticket.add_message!(user: user, body: "Quero reabrir.") }
        .to raise_error(RuntimeError, /Ticket fechado ou cancelado/)
    end
  end
end
