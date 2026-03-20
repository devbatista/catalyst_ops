class KnowledgeBaseArticle < ApplicationRecord
  AUDIENCES = %w[gestor tecnico].freeze

  validates :title, :content, :category, :audience, presence: true
  validates :audience, inclusion: { in: AUDIENCES }

  scope :for_audience, ->(audience) { where(audience: audience) }
end
