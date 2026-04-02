class AddEmbeddingToKnowledgeBaseArticles < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TABLE knowledge_base_articles
      ADD COLUMN IF NOT EXISTS embedding vector(1536);
    SQL

    execute <<~SQL
      CREATE INDEX IF NOT EXISTS index_knowledge_base_articles_on_embedding
      ON knowledge_base_articles
      USING ivfflat (embedding vector_cosine_ops)
      WITH (lists = 100);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX IF EXISTS index_knowledge_base_articles_on_embedding;
    SQL

    execute <<~SQL
      ALTER TABLE knowledge_base_articles
      DROP COLUMN IF EXISTS embedding;
    SQL
  end
end
