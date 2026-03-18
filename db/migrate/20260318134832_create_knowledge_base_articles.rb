class CreateKnowledgeBaseArticles < ActiveRecord::Migration[7.1]
  def change
    create_table :knowledge_base_articles, id: :uuid do |t|
      t.string :title
      t.text :content
      t.string :category
      t.string :slug, index: { unique: true }

      t.timestamps
    end
  end
end
