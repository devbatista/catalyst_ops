class Plan < ApplicationRecord
  has_many :subscriptions, primary_key: :external_id, foreign_key: :preapproval_plan_id, class_name: 'Subscription'
  
  validates :name, :reason, :status,
            :external_id, :external_reference,
            :frequency, :frequency_type,
            :transaction_amount,
            presence: true
  validates :external_id, :external_reference, uniqueness: true
  validates :frequency, numericality: { only_integer: true, greater_than: 0 }
  validates :transaction_amount, numericality: { greater_than: 0 }

  STATUSES = %w[active inactive].freeze
  validates :status, inclusion: { in: STATUSES }
end