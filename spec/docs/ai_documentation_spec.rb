require "spec_helper"

RSpec.describe "Documentação para agentes de IA" do
  let(:root_path) { File.expand_path("../..", __dir__) }
  let(:agents_path) { File.join(root_path, "AGENTS.md") }
  let(:index_path) { File.join(root_path, "docs/dev/ai/00_indice.md") }
  let(:docs_path) { File.join(root_path, "docs/dev/ai") }
  let(:domain_paths) { Dir[File.join(docs_path, "*.md")].reject { |path| File.basename(path) == "00_indice.md" }.sort }

  let(:required_domain_files) do
    %w[
      agenda_e_atribuicoes.md
      assinaturas.md
      auditoria_e_operacao.md
      clientes.md
      empresas_e_tenancy.md
      financeiro_e_relatorios.md
      integracoes_e_webhooks.md
      orcamentos.md
      ordens_de_servico.md
      suporte_e_base_conhecimento.md
      usuarios_e_permissoes.md
    ]
  end

  let(:required_sections) do
    [
      "## Quando Ler Este Arquivo",
      "## Visão Geral",
      "## Áreas Relacionadas",
      "## Pontos De Entrada Importantes",
      "## Regras De Negócio",
      "## Estados E Transições",
      "## Riscos Comuns",
      "## Testes Recomendados"
    ]
  end

  def read(path)
    File.read(path, encoding: "UTF-8")
  end

  def markdown_links(content)
    content.scan(/\[[^\]]+\]\(([^)]+)\)/).flatten
  end

  def agent_doc_references(content)
    content.scan(%r{`?(docs/dev/ai/[^`\s]+\.md)`?}).flatten
  end

  it "mantém o ponto de entrada AGENTS.md apontando para todos os domínios" do
    content = read(agents_path)
    references = agent_doc_references(content)

    expect(references).to include("docs/dev/ai/00_indice.md")
    expect(references.map { |path| File.basename(path) } - ["00_indice.md"]).to match_array(required_domain_files)

    references.each do |relative_path|
      expect(File).to exist(File.join(root_path, relative_path))
    end
  end

  it "mantém o índice com links válidos e cobertura completa dos domínios" do
    content = read(index_path)
    links = markdown_links(content)

    expect(links).to match_array(required_domain_files)

    links.each do |relative_path|
      expect(File).to exist(File.join(docs_path, relative_path))
    end
  end

  it "mantém cada documento de domínio com a estrutura mínima para orientar agentes" do
    domain_paths.each do |path|
      content = read(path)

      required_sections.each do |section|
        expect(content).to include(section), "#{File.basename(path)} deve conter #{section}"
      end

      expect(content.scan(/^- /).size).to be >= 10
    end
  end

  it "preserva regras sensíveis que agentes devem considerar antes de alterar código" do
    agents = read(agents_path)
    docs = domain_paths.map { |path| read(path) }.join("\n")

    expect(agents).to include("Preservar isolamento por `company_id`.")
    expect(agents).to include("Respeitar permissões centralizadas em `app/models/ability.rb`.")
    expect(agents).to include("Não alterar assinatura, cobrança, permissões ou lifecycle de OS sem testes.")
    expect(docs).to include("Queries globais na área `app` devem ser tratadas como falha")
    expect(docs).to include("Permissões de backend devem ficar em `Ability`")
    expect(docs).to include("Webhooks devem ser tratados com idempotência.")
    expect(docs).to include("Ações auditadas devem existir em `Audit::ActionCatalog`.")
  end

  it "mantém português acentuado nos termos recorrentes da documentação de IA" do
    content = ([agents_path, index_path] + domain_paths).map { |path| read(path) }.join("\n")

    expect(content).not_to match(/\bAreas\b/)
    expect(content).not_to match(/\bDominios\b/)
    expect(content).not_to match(/\bRelatorios\b/)
    expect(content).not_to match(/\brelatorios\b/)
    expect(content).not_to match(/\bsensivel\b/)
  end
end
