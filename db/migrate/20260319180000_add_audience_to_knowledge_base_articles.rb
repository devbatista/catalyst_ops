class AddAudienceToKnowledgeBaseArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :knowledge_base_articles, :audience, :string, null: false, default: "gestor"
    add_index :knowledge_base_articles, :audience
  end
end
