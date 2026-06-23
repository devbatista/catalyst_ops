require "rails_helper"

RSpec.describe Plan, type: :model do
  describe "associações" do
    it "possui muitas assinaturas pelo identificador externo do plano" do
      plan = create(:plan, external_id: "plan_associado")
      expected_subscription = create(:subscription, subscription_plan: plan)
      create(:subscription)

      expect(plan.subscriptions).to contain_exactly(expected_subscription)
    end

    it "não retorna assinaturas vinculadas a outro identificador externo" do
      plan = create(:plan, external_id: "plan_principal")
      other_plan = create(:plan, external_id: "plan_outro")
      create(:subscription, subscription_plan: other_plan)

      expect(plan.subscriptions).to be_empty
    end
  end

  describe "validações" do
    subject(:plan) { build(:plan) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:reason) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_presence_of(:external_reference) }
    it { is_expected.to validate_presence_of(:frequency) }
    it { is_expected.to validate_presence_of(:frequency_type) }
    it { is_expected.to validate_presence_of(:transaction_amount) }
    it { is_expected.to validate_uniqueness_of(:external_id) }
    it { is_expected.to validate_uniqueness_of(:external_reference) }
    it { is_expected.to validate_numericality_of(:frequency).only_integer.is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:transaction_amount).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active inactive]) }

    it "é válido com os dados padrão da factory" do
      expect(build(:plan)).to be_valid
    end

    it "permite status inativo" do
      plan = build(:plan, status: "inactive")

      expect(plan).to be_valid
    end

    it "rejeita frequência igual a zero" do
      plan = build(:plan, frequency: 0)

      aggregate_failures do
        expect(plan).not_to be_valid
        expect(plan.errors[:frequency]).to include("deve ser maior que 0")
      end
    end

    it "rejeita frequência fracionada" do
      plan = build(:plan, frequency: 1.5)

      aggregate_failures do
        expect(plan).not_to be_valid
        expect(plan.errors.details[:frequency]).to include(error: :not_an_integer, value: 1.5)
      end
    end

    it "rejeita valor de transação igual a zero para plano pago" do
      plan = build(:plan, transaction_amount: 0)

      aggregate_failures do
        expect(plan).not_to be_valid
        expect(plan.errors[:transaction_amount]).to include("deve ser maior que 0 para planos pagos")
      end
    end

    it "permite valor de transação igual a zero para plano gratuito" do
      plan = build(:plan, :starter)

      expect(plan).to be_valid
    end

    it "permite limites operacionais opcionais do plano" do
      plan = build(
        :plan,
        max_technicians: 5,
        max_orders: 100,
        max_budgets: 50,
        support_level: "prioritario"
      )

      expect(plan).to be_valid
    end
  end
end
