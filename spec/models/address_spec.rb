require "rails_helper"
require "cpf_cnpj"

RSpec.describe Address, type: :model do
  let(:company) {
    Company.create!(
      name: "Empresa Teste",
      document: CNPJ.generate,
      email: "empresa@email.com",
      phone: "1133334444",
    )
  }

  let(:client) {
    Client.create!(
      name: "Teste",
      document: CPF.generate,
      email: "teste@email.com",
      phone: "11999999999",
      company: company,
    )
  }

  subject {
    described_class.new(
      street: "Rua Exemplo",
      number: "123",
      neighborhood: "Centro",
      zip_code: "12345-678",
      city: "São Paulo",
      state: "SP",
      country: "Brasil",
      address_type: "principal",
      client: client,
    )
  }

  it "é válido com atributos obrigatórios" do
    expect(subject).to be_valid
  end

  it "é inválido sem zip_code" do
    subject.zip_code = nil
    expect(subject).to_not be_valid
  end

  it "formata zip_code automaticamente" do
    subject.zip_code = "12345678"
    subject.valid?
    expect(subject.zip_code).to eq("12345-678")
  end

  it "é inválido com zip_code em formato impossível de formatar" do
    subject.zip_code = "1234"
    expect(subject).to_not be_valid
  end

  it "é inválido com zip_code contendo letras" do
    subject.zip_code = "12a45-67b"
    expect(subject).to_not be_valid
  end

  it "é inválido sem cidade" do
    subject.city = nil
    expect(subject).to_not be_valid
  end

  it "é inválido com cidade muito curta" do
    subject.city = "A"
    expect(subject).to_not be_valid
  end

  it "é inválido sem estado" do
    subject.state = nil
    expect(subject).to_not be_valid
  end

  it "é inválido com estado fora do padrão" do
    subject.state = "SaoPaulo"
    expect(subject).to_not be_valid
    subject.state = "S1"
    expect(subject).to_not be_valid
  end

  it "é inválido sem país" do
    subject.country = nil
    expect(subject).to_not be_valid
  end

  it "é inválido com país muito curto" do
    subject.country = "B"
    expect(subject).to_not be_valid
  end

  it "é inválido sem rua" do
    subject.street = nil
    expect(subject).to_not be_valid
  end

  it "é inválido com rua muito curta" do
    subject.street = "A"
    expect(subject).to_not be_valid
  end

  it "é inválido sem número" do
    subject.number = nil
    expect(subject).to_not be_valid
  end

  it "é inválido sem bairro" do
    subject.neighborhood = nil
    expect(subject).to_not be_valid
  end

  it "é inválido com bairro muito curto" do
    subject.neighborhood = "A"
    expect(subject).to_not be_valid
  end

  it "é inválido com tipo de endereço não permitido" do
    subject.address_type = "invalido"
    expect(subject).to_not be_valid
  end

  it "aceita tipos de endereço válidos" do
    %w[principal entrega cobranca outros].each do |tipo|
      subject.address_type = tipo
      expect(subject).to be_valid
    end
  end

  it "pertence a um cliente" do
    expect(subject.client).to eq(client)
  end
end