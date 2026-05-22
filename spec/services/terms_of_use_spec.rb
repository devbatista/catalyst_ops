require "rails_helper"

RSpec.describe TermsOfUse do
  it "expõe a versão atual dos termos" do
    expect(described_class.current_version).to eq("2026-03-21")
  end

  it "expõe o título dos termos" do
    expect(described_class.title).to eq("Contrato de Utilização do CatalystOps")
  end
end
