class SubscriptionReconciliationEvent < ApplicationRecord
  RESULT_STATUSES = %w[success error].freeze

  belongs_to :subscription
  belongs_to :company

  validates :source_job, presence: true
  validates :payment_method, presence: true
  validates :gateway_identifier, presence: true
  validates :local_status_before, presence: true
  validates :local_status_after, presence: true
  validates :processed_at, presence: true
  validates :result_status, inclusion: { in: RESULT_STATUSES }

  scope :recent, -> { order(processed_at: :desc, created_at: :desc) }
  scope :divergent, -> { where(divergent: true) }
  scope :errors, -> { where(result_status: "error") }
end
