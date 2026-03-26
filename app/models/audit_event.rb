class AuditEvent < ApplicationRecord
  SOURCES = %w[app admin webhook job system].freeze

  belongs_to :company, optional: true

  validates :action, presence: true
  validates :action, inclusion: { in: Audit::ActionCatalog::ALL }
  validates :occurred_at, presence: true
  validates :source, inclusion: { in: SOURCES }, allow_blank: true
  validates :metadata, presence: true

  scope :recent, -> { order(occurred_at: :desc, created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) if action.present? }
  scope :by_source, ->(source) { where(source: source) if source.present? }
  scope :by_company, ->(company_id) { where(company_id: company_id) if company_id.present? }
  scope :between, lambda { |from, to|
    scope = all
    scope = scope.where("occurred_at >= ?", from) if from.present?
    scope = scope.where("occurred_at <= ?", to) if to.present?
    scope
  }
end
