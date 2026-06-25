require "rails_helper"

RSpec.describe "app/configurations/_subscription", type: :view do
  let(:user) { create(:user, :gestor, company: company, active: true) }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  context "quando a empresa está no plano Starter" do
    let(:starter_plan) { create(:plan, :starter) }
    let(:company) { create(:company, plan: starter_plan, payment_method: "pix", active: true) }

    before do
      create(:subscription, company: company, subscription_plan: starter_plan, status: :active)
    end

    it "mostra cards dos planos pagos ativos com formas de pagamento" do
      Plan.paid.update_all(status: "inactive")

      basico = create(:plan, name: "Basico", reason: "Plano básico", transaction_amount: 99.0)
      profissional = create(:plan, :profissional, max_technicians: 5, max_orders: 50, max_budgets: 20, support_level: "E-mail")
      create(:plan, :starter)

      render partial: "app/configurations/subscription"

      aggregate_failures do
        expect(rendered).to include("Planos pagos disponíveis")
        expect(rendered).to include(basico.name)
        expect(rendered).to include(basico.reason)
        expect(rendered).to include(profissional.name)
        expect(rendered).to include("paid-subscription-card")
        expect(rendered).to include("Compare os planos e escolha uma opção para continuar.")
        expect(rendered).not_to include("Formas de pagamento</div>")
        expect(rendered).to include("PIX")
        expect(rendered).to include("Cartão")
        expect(rendered).to include("Boleto")
        expect(rendered).to include("Escolher plano")
        expect(rendered).to include("paidSubscriptionModal")
        expect(rendered).to include("start_paid_subscription")
        expect(rendered).to include('type="checkbox"')
        expect(rendered).not_to include('type="radio"')
        expect(rendered).not_to include("starter-gratuito")
      end
    end

    it "mostra mensagem quando não há plano pago ativo" do
      Plan.paid.update_all(status: "inactive")

      render partial: "app/configurations/subscription"

      expect(rendered).to include("Nenhum plano pago disponível no momento.")
    end
  end

  context "quando a empresa está em um plano pago" do
    let(:paid_plan) { create(:plan, :profissional) }
    let(:company) { create(:company, plan: paid_plan, payment_method: "boleto", active: true) }

    before do
      create(:subscription, company: company, subscription_plan: paid_plan, status: :active)
      create(:plan, :enterprise)
    end

    it "não mostra cards de adesão" do
      render partial: "app/configurations/subscription"

      aggregate_failures do
        expect(rendered).not_to include("Planos pagos disponíveis")
        expect(rendered).not_to include("Compare os planos")
        expect(rendered).not_to include("paidSubscriptionModal")
        expect(rendered).to include("Cancelamento")
      end
    end
  end
end
