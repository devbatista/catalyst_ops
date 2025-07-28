require "rails_helper"

RSpec.describe Client, type: :model do
  describe "validações" do
    subject { create(:client) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(100) }

    it { should validate_presence_of(:document) }
    it { should validate_uniqueness_of(:document).case_insensitive }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }

    it { should validate_presence_of(:phone) }

    context "validação de formato do e-mail" do
      it "aceita e-mail válido" do
        client = build(:client, email: "teste@exemplo.com")
        expect(client).to be_valid
      end

      it "rejeita e-mail inválido" do
        client = build(:client, email: "email_invalido")
        expect(client).not_to be_valid
        expect(client.errors[:email]).to include("is invalid")
      end
    end

    context "validação de formato do telefone" do
      it "aceita telefone válido" do
        client = build(:client, phone: "11987654321")
        expect(client).to be_valid
      end

      it "aceita telefone formatado" do
        client = build(:client, phone: "(11) 98765-4321")
        expect(client).to be_valid
      end
    end

    context "validação de documento" do
      it "aceita CPF válido" do
        client = build(:client, document: CPF.generate)
        expect(client).to be_valid
      end

      it "aceita CNPJ válido" do
        client = build(:client, document: CNPJ.generate)
        expect(client).to be_valid
      end

      it "rejeita CPF inválido" do
        client = build(:client, document: "11111111111")
        expect(client).not_to be_valid
        expect(client.errors[:document]).to include("deve ser um CPF ou CNPJ válido")
      end

      it "rejeita CNPJ inválido" do
        client = build(:client, document: "11111111111111")
        expect(client).not_to be_valid
        expect(client.errors[:document]).to include("deve ser um CPF ou CNPJ válido")
      end
    end
  end

  describe "associações" do
    it { should have_many(:order_services).dependent(:destroy) }
  end

  describe "escopos" do
    let!(:cliente_ativo) { create(:client) }
    let!(:cliente_antigo) { create(:client) }

    before do
      create(:order_service, client: cliente_ativo, company: cliente_ativo.company, created_at: 1.month.ago)
      create(:order_service, client: cliente_antigo, company: cliente_ativo.company, created_at: 8.months.ago)
    end

    it "retorna clientes ativos" do
      expect(Client.active_clients).to include(cliente_ativo)
      expect(Client.active_clients).not_to include(cliente_antigo)
    end

    it "filtra por nome" do
      cliente_com_nome = create(:client, name: "João Silva")
      expect(Client.by_name("João")).to include(cliente_com_nome)
      expect(Client.by_name("Maria")).not_to include(cliente_com_nome)
    end

    it "ordena pelo mais recente" do
      create(:client)
      sleep(1)
      cliente2 = create(:client)
      expect(Client.recent.first).to eq(cliente2)
    end
  end

  describe "callbacks" do
    it "normaliza atributos antes da validação" do
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

  describe "métodos de documento" do
    let(:cpf_number) { CPF.generate }
    let(:cnpj_number) { CNPJ.generate }
    let(:cpf_client) { create(:client, document: cpf_number) }
    let(:cnpj_client) { create(:client, document: cnpj_number) }

    it "identifica CPF corretamente" do
      expect(cpf_client.cpf?).to be true
      expect(cpf_client.cnpj?).to be false
      expect(cpf_client.document_type).to eq("CPF")
      expect(cpf_client.individual_customer?).to be true
      expect(cpf_client.corporate_customer?).to be false
    end

    it "identifica CNPJ corretamente" do
      expect(cnpj_client.cpf?).to be false
      expect(cnpj_client.cnpj?).to be true
      expect(cnpj_client.document_type).to eq("CNPJ")
      expect(cnpj_client.individual_customer?).to be false
      expect(cnpj_client.corporate_customer?).to be true
    end

    it "formata documento corretamente" do
      expect(cpf_client.formatted_document).to eq(CPF.new(cpf_number).formatted)
      expect(cnpj_client.formatted_document).to eq(CNPJ.new(cnpj_number).formatted)
    end
  end

  describe "formatação de telefone" do
    it "formata celular corretamente" do
      client = create(:client, phone: "11987654321")
      expect(client.formatted_phone).to eq("(11) 98765-4321")
    end

    it "formata telefone fixo corretamente" do
      client = create(:client, phone: "1133334444")
      expect(client.formatted_phone).to eq("(11) 3333-4444")
    end

    it "não permite telefone com menos de 10 dígitos" do
      client = build(:client, phone: "123456789") # 9 dígitos
      expect(client).not_to be_valid
      expect(client.errors[:phone]).to include("is too short (minimum is 10 characters)")
    end
  end

  describe "métodos de negócio" do
    let(:client) { create(:client) }

    before do
      create(:order_service, client: client, company: client.company, status: :agendada)
      create(:order_service, client: client, company: client.company, status: :em_andamento)
      create(:order_service, client: client, company: client.company, status: :concluida)
      create(:order_service, client: client, company: client.company, status: :cancelada)
    end

    it "retorna ordens ativas" do
      expect(client.active_orders.count).to eq(2)
    end

    it "conta ordens pendentes" do
      expect(client.pending_orders_count).to eq(1)
    end

    it "conta ordens concluídas" do
      expect(client.completed_orders_count).to eq(1)
    end

    it "identifica se possui ordens ativas" do
      expect(client.has_active_orders?).to be true
    end

    it "determina se pode ser deletado" do
      expect(client.can_be_deleted?).to be false
    end
  end

  describe "cálculos financeiros" do
    let(:client) { create(:client) }

    before do
      order1 = create(:order_service, client: client, company: client.company)
      order2 = create(:order_service, client: client, company: client.company)
      create(:service_item, order_service: order1, quantity: 2, unit_price: 50.0)
      create(:service_item, order_service: order2, quantity: 1, unit_price: 100.0)
    end

    it "calcula o valor total das ordens" do
      expect(client.total_orders_value).to eq(200.0)
    end

    it "formata o valor total" do
      expect(client.formatted_total_value).to eq("R$ 200.00")
    end
  end

  describe "factory" do
    it "possui uma factory válida" do
      expect(build(:client)).to be_valid
    end

    it "possui traits de factory válidos" do
      expect(build(:client, :with_cnpj)).to be_valid
      expect(build(:client, :individual)).to be_valid
    end

    it "cria documentos únicos" do
      client1 = create(:client)
      client2 = create(:client)
      expect(client1.document).not_to eq(client2.document)
    end
  end
end