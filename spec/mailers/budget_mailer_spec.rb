require "rails_helper"

RSpec.describe BudgetMailer, type: :mailer do
  before do
    ActionMailer::Base.default_url_options[:host] = "example.com"
  end

  describe "#approval_request_to_client" do
    it "envia link de aprovação para o cliente" do
      budget = build_budget
      budget.valid_until = 3.days.from_now.to_date

      email = described_class.approval_request_to_client(budget, "token-123", sender_name: "Maria")

      expect(email.to).to eq([budget.client.email])
      expect(email.subject).to eq("Aprovação do Orçamento ##{budget.code}")
      expect(email.body.encoded).to include("Maria")
      expect(email.body.encoded).to include("token-123")
    end
  end

  describe "#notify_manager_order_service_created" do
    it "envia aviso para gestores da empresa" do
      budget = create_budget
      manager = create(:user, :gestor, company: budget.company, email: "gestor@example.com")
      order_service = create(:order_service, company: budget.company, client: budget.client)

      email = described_class.notify_manager_order_service_created(budget, order_service, approver_role: "cliente")

      expect(email.to).to eq([manager.email])
      expect(email.subject).to include("OS ##{order_service.code}")
      expect(email.body.encoded).to include(order_service.code.to_s)
      expect(email.body.encoded).to include(budget.code.to_s)
    end

    it "não envia quando não há destinatário elegível" do
      budget = create_budget
      order_service = create(:order_service, company: budget.company, client: budget.client)

      email = described_class.notify_manager_order_service_created(budget, order_service, approver_role: "cliente")

      expect(email.message).to be_a(ActionMailer::Base::NullMail)
    end
  end

  def build_budget
    plan = build(:plan)
    company = build(:company, plan: plan)
    client = build(:client, company: company)
    build(:budget, company: company, client: client)
  end

  def create_budget
    plan = create(:plan, max_orders: 10)
    company = create(:company, plan: plan)
    create(:subscription, company: company, subscription_plan: plan)
    client = create(:client, company: company)
    create(:budget, company: company, client: client)
  end
end
