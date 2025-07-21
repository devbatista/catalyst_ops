require "rails_helper"

RSpec.describe Client, type: :model do
  describe "validations" do
    subject { create(:client) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(100) }

    it { should validate_presence_of(:document) }
    it { should validate_uniqueness_of(:document).case_insensitive }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }

    it { should validate_presence_of(:phone) }
    it { should validate_length_of(:address).is_at_most(500) }

    context "email format validation" do
      it "accepts valid email" do
        client = build(:client, email: "test@example.com")
        expect(client).to be_valid
      end

      it "rejects invalid email" do
        client = build(:client, email: "invalid_email")
        expect(client).not_to be_valid
        expect(client.errors[:email]).to include("is invalid")
      end
    end

    context "phone format validation" do
      it "accepts valid phone" do
        client = build(:client, phone: "11987654321")
        expect(client).to be_valid
      end

      it "accepts formatted phone" do
        client = build(:client, phone: "(11) 98765-4321")
        expect(client).to be_valid
      end
    end

    context "document validation" do
      it "accepts valid CPF" do
        client = build(:client, document: CPF.generate)
        expect(client).to be_valid
      end

      it "accepts valid CNPJ" do
        client = build(:client, document: CNPJ.generate)
        expect(client).to be_valid
      end

      it "rejects invalid CPF" do
        client = build(:client, document: "11111111111")
        expect(client).not_to be_valid
        expect(client.errors[:document]).to include("deve ser um CPF ou CNPJ válido")
      end

      it "rejects invalid CNPJ" do
        client = build(:client, document: "11111111111111")
        expect(client).not_to be_valid
        expect(client.errors[:document]).to include("deve ser um CPF ou CNPJ válido")
      end
    end
  end

  describe "associations" do
    it { should have_many(:order_services).dependent(:destroy) }
  end

  describe "scopes" do
    let!(:active_client) { create(:client) }
    let!(:old_client) { create(:client) }

    before do
      create(:order_service, client: active_client, created_at: 1.month.ago)
      create(:order_service, client: old_client, created_at: 8.months.ago)
    end

    it "returns active clients" do
      expect(Client.active_clients).to include(active_client)
      expect(Client.active_clients).not_to include(old_client)
    end

    it "filters by name" do
      client_with_name = create(:client, name: "João Silva")
      expect(Client.by_name("João")).to include(client_with_name)
      expect(Client.by_name("Maria")).not_to include(client_with_name)
    end

    it "orders by most recent" do
      create(:client)
      sleep(1)
      client2 = create(:client)
      expect(Client.recent.first).to eq(client2)
    end
  end

  describe "callbacks" do
    it "normalizes attributes before validation" do
      client = build(:client,
                     name: "  joão silva  ",
                     email: "  JOAO@EXAMPLE.COM  ",
                     document: "111.444.777-35",
                     phone: "(11) 98765-4321")
      client.valid?
      expect(client.name).to eq("João Silva")
      expect(client.email).to eq("joao@example.com")
      expect(client.document).to eq("11144477735")
      expect(client.phone).to eq("11987654321")
    end
  end

  describe "document methods" do
    let(:cpf_number) { CPF.generate }
    let(:cnpj_number) { CNPJ.generate }
    let(:cpf_client) { create(:client, document: cpf_number) }
    let(:cnpj_client) { create(:client, document: cnpj_number) }

    it "identifies CPF correctly" do
      expect(cpf_client.cpf?).to be true
      expect(cpf_client.cnpj?).to be false
      expect(cpf_client.document_type).to eq("CPF")
      expect(cpf_client.individual_customer?).to be true
      expect(cpf_client.corporate_customer?).to be false
    end

    it "identifies CNPJ correctly" do
      expect(cnpj_client.cpf?).to be false
      expect(cnpj_client.cnpj?).to be true
      expect(cnpj_client.document_type).to eq("CNPJ")
      expect(cnpj_client.individual_customer?).to be false
      expect(cnpj_client.corporate_customer?).to be true
    end

    it "formats document correctly" do
      expect(cpf_client.formatted_document).to eq(CPF.new(cpf_number).formatted)
      expect(cnpj_client.formatted_document).to eq(CNPJ.new(cnpj_number).formatted)
    end
  end

  describe "phone formatting" do
    it "formats mobile phone correctly" do
      client = create(:client, phone: "11987654321")
      expect(client.formatted_phone).to eq("(11) 98765-4321")
    end

    it "formats landline phone correctly" do
      client = create(:client, phone: "1133334444")
      expect(client.formatted_phone).to eq("(11) 3333-4444")
    end

    it "does not allow phone with less than 10 digits" do
      client = build(:client, phone: "123456789") # 9 dígitos
      expect(client).not_to be_valid
      expect(client.errors[:phone]).to include("is too short (minimum is 10 characters)")
    end
  end

  describe "business methods" do
    let(:client) { create(:client) }

    before do
      create(:order_service, client: client, status: :agendada)
      create(:order_service, client: client, status: :em_andamento)
      create(:order_service, client: client, status: :concluida)
      create(:order_service, client: client, status: :cancelada)
    end

    it "returns active orders" do
      expect(client.active_orders.count).to eq(2)
    end

    it "counts pending orders" do
      expect(client.pending_orders_count).to eq(1)
    end

    it "counts completed orders" do
      expect(client.completed_orders_count).to eq(1)
    end

    it "identifies if has active orders" do
      expect(client.has_active_orders?).to be true
    end

    it "determines if can be deleted" do
      expect(client.can_be_deleted?).to be false
    end
  end

  describe "financial calculations" do
    let(:client) { create(:client) }

    before do
      order1 = create(:order_service, client: client)
      order2 = create(:order_service, client: client)
      create(:service_item, order_service: order1, quantity: 2, unit_price: 50.0)
      create(:service_item, order_service: order2, quantity: 1, unit_price: 100.0)
    end

    it "calculates total orders value" do
      expect(client.total_orders_value).to eq(200.0)
    end

    it "formats total value" do
      expect(client.formatted_total_value).to eq("R$ 200.00")
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:client)).to be_valid
    end

    it "has valid trait factories" do
      expect(build(:client, :with_cnpj)).to be_valid
      expect(build(:client, :individual)).to be_valid
    end

    it "creates unique documents" do
      client1 = create(:client)
      client2 = create(:client)
      expect(client1.document).not_to eq(client2.document)
    end
  end
end
