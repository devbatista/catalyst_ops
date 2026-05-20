require "rails_helper"

RSpec.describe KnowledgeBaseArticle, type: :model do
  describe "validações" do
    subject(:article) { build(:knowledge_base_article) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:audience) }
    it { is_expected.to validate_inclusion_of(:audience).in_array(%w[gestor tecnico]) }

    it "é válido para público gestor" do
      article = build(:knowledge_base_article, audience: "gestor")

      expect(article).to be_valid
    end

    it "é válido para público técnico" do
      article = build(:knowledge_base_article, audience: "tecnico")

      expect(article).to be_valid
    end
  end

  describe ".for_audience" do
    it "retorna apenas artigos do público informado" do
      gestor_article = create(:knowledge_base_article, audience: "gestor")
      tecnico_article = create(:knowledge_base_article, audience: "tecnico")

      result = described_class.where(id: [gestor_article.id, tecnico_article.id]).for_audience("gestor")

      expect(result).to contain_exactly(gestor_article)
    end
  end
end
