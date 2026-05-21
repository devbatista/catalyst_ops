require "rails_helper"

RSpec.describe Budget, type: :model do
  subject(:budget) { build(:budget, company: company, client: client) }

  let(:company) { company_with_active_subscription }
  let(:client) { create(:client, company: company) }

  describe "associações" do
    it { should belong_to(:client) }
    it { should belong_to(:order_service).optional }
    it { should have_many(:service_items).dependent(:destroy) }
    it { should accept_nested_attributes_for(:service_items).allow_destroy(true) }

    it "pertence obrigatoriamente a uma empresa" do
      association = described_class.reflect_on_association(:company)

      aggregate_failures do
        expect(association.macro).to eq(:belongs_to)
        expect(association.options[:optional]).not_to eq(true)
      end
    end
  end

  describe "validações" do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_least(3).is_at_most(120) }
    it { should validate_presence_of(:status) }
    it { should validate_numericality_of(:estimated_delivery_days).only_integer.is_greater_than(0).allow_nil }

    it "exige código quando não é possível gerar sequência" do
      budget = build(:budget, company: nil, client: nil, code: nil)

      expect(budget).not_to be_valid
      expect(budget.errors[:code]).to include("não pode ficar em branco")
    end

    it "não permite valor total negativo quando não há itens para recalcular" do
      budget = build(:budget, company: company, client: client, total_value: -1)
      budget.service_items.clear

      expect(budget).not_to be_valid
      expect(budget.errors[:total_value]).to include("deve ser maior ou igual a 0")
    end

    it "exige empresa igual à empresa do cliente" do
      other_company = company_with_active_subscription
      budget = build(:budget, company: other_company, client: client)

      expect(budget).not_to be_valid
      expect(budget.errors[:company_id]).to include("deve ser a mesma empresa do cliente")
    end

    it "não permite itens de serviço totalmente em branco" do
      budget = build(:budget, company: company, client: client)
      budget.service_items.clear
      budget.service_items.build

      expect(budget).not_to be_valid
      expect(budget.errors[:base]).to include("Não é possível deixar itens de serviço em branco.")
    end

    it "respeita limite de orçamentos do plano" do
      plan = create(:plan, max_budgets: 1)
      company = create(:company, plan: plan)
      create(:subscription, company: company, subscription_plan: plan, status: :active)
      client = create(:client, company: company)
      create(:budget, company: company, client: client)

      budget = build(:budget, company: company, client: client)

      expect(budget).not_to be_valid
      expect(budget.errors[:base]).to include("Limite de orçamentos atingido para o plano atual da empresa.")
    end
  end

  describe "callbacks" do
    it "preenche a empresa a partir do cliente na criação" do
      budget = create(:budget, company: nil, client: client)

      expect(budget.company).to eq(client.company)
    end

    it "define código sequencial por empresa" do
      first_budget = create(:budget, company: company, client: client, code: nil)
      second_budget = create(:budget, company: company, client: client, code: nil)

      expect(second_budget.code).to eq(first_budget.code + 1)
    end

    it "calcula o valor total pelos itens de serviço" do
      budget = build(:budget, company: company, client: client, total_value: 0)
      budget.service_items.clear
      budget.service_items.build(description: "Servico A", quantity: 2, unit_price: 45.50)
      budget.service_items.build(description: "Servico B", quantity: 1, unit_price: 10)

      budget.valid?

      expect(budget.total_value).to eq(101.0)
    end
  end

  describe "métodos de negócio" do
    it "formata o valor total" do
      budget.total_value = 123.45

      expect(budget.formatted_total_value).to eq("R$ 123.45")
    end

    it "permite edição apenas em rascunho ou rejeitado" do
      expect(build(:budget, status: :rascunho)).to be_editable
      expect(build(:budget, status: :rejeitado)).to be_editable
      expect(build(:budget, status: :enviado)).not_to be_editable
      expect(build(:budget, status: :aprovado)).not_to be_editable
      expect(build(:budget, status: :cancelado)).not_to be_editable
    end

    it "gera e encontra token de aprovação válido" do
      budget = create(:budget, company: company, client: client)
      token = budget.approval_token

      expect(described_class.find_by_approval_token(token)).to eq(budget)
    end

    it "retorna nil para token de aprovação inválido" do
      expect(described_class.find_by_approval_token("token-invalido")).to be_nil
    end

    it "marca orçamento como enviado para aprovação" do
      budget = create(:budget, company: company, client: client, status: :rascunho, approved_at: Time.current, rejected_at: Time.current, rejection_reason: "Antigo")

      budget.send_for_approval!

      aggregate_failures do
        expect(budget).to be_enviado
        expect(budget.approval_sent_at).to be_present
        expect(budget.approved_at).to be_nil
        expect(budget.rejected_at).to be_nil
        expect(budget.rejection_reason).to be_nil
      end
    end

    it "rejeita orçamento com motivo" do
      budget = create(:budget, company: company, client: client, status: :enviado, approved_at: Time.current)

      budget.reject!(rejection_reason: "Cliente recusou a proposta")

      aggregate_failures do
        expect(budget).to be_rejeitado
        expect(budget.rejected_at).to be_present
        expect(budget.approved_at).to be_nil
        expect(budget.rejection_reason).to eq("Cliente recusou a proposta")
      end
    end

    it "não rejeita orçamento sem motivo" do
      budget = create(:budget, company: company, client: client, status: :enviado)

      expect do
        budget.reject!(rejection_reason: " ")
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(budget.errors[:rejection_reason]).to include("não pode ficar em branco")
    end
  end

  describe "factory" do
    it "possui uma factory válida" do
      expect(budget).to be_valid
    end
  end

  def company_with_active_subscription
    plan = create(:plan)
    company = create(:company, plan: plan)
    create(:subscription, company: company, subscription_plan: plan, status: :active)
    company
  end
end
