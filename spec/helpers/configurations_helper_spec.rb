require "rails_helper"

RSpec.describe ConfigurationsHelper, type: :helper do
  let(:plan) { create(:plan, name: "Profissional") }
  let(:company) { create(:company, plan: plan) }
  let(:responsible) { create(:user, :gestor, company: company, active: true) }

  before do
    company.update!(responsible: responsible)
  end

  describe "#company_responsible?" do
    it "identifica o responsável da empresa" do
      other_user = create(:user, :gestor, company: company, active: true)

      aggregate_failures do
        expect(helper.company_responsible?(responsible)).to be(true)
        expect(helper.company_responsible?(other_user)).to be(false)
      end
    end
  end

  describe "#current_company_plan" do
    it "prioriza plano da assinatura ativa e usa fallback da empresa" do
      active_plan = create(:plan, name: "Enterprise")
      create(:subscription, company: company, subscription_plan: active_plan, status: :active)

      aggregate_failures do
        expect(helper.current_company_plan(responsible)).to eq(active_plan)
        company.subscriptions.delete_all
        expect(helper.current_company_plan(responsible)).to eq(plan)
      end
    end
  end

  describe "#can_promote_manager?" do
    it "permite apenas responsável em plano diferente do básico" do
      other_user = create(:user, :gestor, company: company, active: true)

      aggregate_failures do
        expect(helper.can_promote_manager?(responsible)).to be(true)
        expect(helper.can_promote_manager?(other_user)).to be(false)
        plan.update!(name: "Basico")
        expect(helper.can_promote_manager?(responsible)).to be(false)
      end
    end
  end

  describe "coleções da empresa" do
    it "retorna gestores, técnicos e assinatura atual" do
      subscription = create(:subscription, company: company, subscription_plan: plan, status: :active)
      technician = create(:user, :tecnico, company: company, active: true)

      aggregate_failures do
        expect(helper.company_managers(responsible)).to include(responsible)
        expect(helper.company_technicians(responsible)).to include(technician)
        expect(helper.current_company_subscription(responsible)).to eq(subscription)
      end
    end
  end

  describe "#subscription_badge_class" do
    it "retorna classes por status e fallback" do
      aggregate_failures do
        expect(helper.subscription_badge_class("active")).to eq("success")
        expect(helper.subscription_badge_class("pending")).to eq("warning")
        expect(helper.subscription_badge_class("canceled")).to eq("danger")
        expect(helper.subscription_badge_class("expired")).to eq("secondary")
        expect(helper.subscription_badge_class("outro")).to eq("secondary")
      end
    end
  end
end
