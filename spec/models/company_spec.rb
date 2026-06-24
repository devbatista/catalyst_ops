require 'rails_helper'

RSpec.describe Company, type: :model do
  let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    allow(UserMailer).to receive(:welcome_email).and_return(mail_delivery)
  end

  describe "escopos e estado" do
    it "normaliza website sem protocolo para https" do
      company = build(:company, website: "www.exemplo.com.br")

      expect(company).to be_valid
      expect(company.website).to eq("https://www.exemplo.com.br")
    end

    it "retorna empresas com mais ordens de serviço primeiro" do
      company_with_two = company_with_subscription
      company_with_one = company_with_subscription
      client_one = create(:client, company: company_with_one)
      client_two = create(:client, company: company_with_two)
      create(:order_service, company: company_with_two, client: client_two)
      create(:order_service, company: company_with_two, client: client_two)
      create(:order_service, company: company_with_one, client: client_one)

      ordered_companies = described_class.top_by_order_services(100).select { |company| [company_with_one.id, company_with_two.id].include?(company.id) }

      expect(ordered_companies).to eq([company_with_two, company_with_one])
    end

    it "busca por nome, e-mail ou documento" do
      company = create(:company, name: "Oficina Central", email: "central@example.com")

      expect(described_class.search("Central")).to include(company)
      expect(described_class.search("central@example.com")).to include(company)
    end

    it "ativa e desativa empresa e usuários" do
      company = company_with_subscription
      company.update!(active: false)
      user = create(:user, company: company, active: false)

      company.activate!
      expect(company.reload).to be_active
      expect(user.reload).to be_active

      company.deactivate!
      expect(company.reload).not_to be_active
      expect(user.reload).not_to be_active
    end
  end

  describe "limites do plano atual" do
    it "retorna plano e limites da assinatura atual" do
      plan = create(:plan, max_technicians: 2, max_orders: 3, support_level: "prioritario")
      company = create(:company, plan: plan)
      create(:subscription, company: company, subscription_plan: plan, status: :active)

      aggregate_failures do
        expect(company.current_plan).to eq(plan)
        expect(company.max_technicians).to eq(2)
        expect(company.max_orders).to eq(3)
        expect(company.support_level).to eq("prioritario")
      end
    end

    it "valida se pode adicionar técnico respeitando limite" do
      plan = create(:plan, max_technicians: 1)
      company = create(:company, plan: plan)
      create(:subscription, company: company, subscription_plan: plan, status: :active)
      expect(company.can_add_technician?).to be(true)

      create(:user, :tecnico, company: company, active: true)

      expect(company.can_add_technician?).to be(false)
    end

    it "identifica empresa com plano Starter gratuito" do
      plan = create(:plan, :starter)
      company = create(:company, plan: plan)
      create(:subscription, company: company, subscription_plan: plan, status: :active)

      expect(company).to be_starter_plan
    end

    it "valida se pode criar OS respeitando limite" do
      plan = create(:plan, max_orders: 1)
      company = create(:company, plan: plan)
      create(:subscription, company: company, subscription_plan: plan, status: :active)
      client = create(:client, company: company)

      expect(company.can_create_order?).to be(true)

      create(:order_service, company: company, client: client)

      expect(company.can_create_order?).to be(false)
    end
  end

  describe "#pdf_customization_available?" do
    it "is available for Profissional plan" do
      company = build(:company, plan: build(:plan, :profissional))

      expect(company.pdf_customization_available?).to be(true)
    end

    it "is available for Enterprise plan" do
      company = build(:company, plan: build(:plan, :enterprise))

      expect(company.pdf_customization_available?).to be(true)
    end

    it "is not available for Basico plan" do
      company = build(:company, plan: build(:plan))

      expect(company.pdf_customization_available?).to be(false)
    end

    it "is not available when company has no plan" do
      company = build(:company, plan: nil)

      expect(company.pdf_customization_available?).to be(false)
    end
  end

  def company_with_subscription
    plan = create(:plan)
    company = create(:company, plan: plan)
    create(:subscription, company: company, subscription_plan: plan, status: :active)
    company
  end
end
