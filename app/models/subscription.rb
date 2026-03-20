class Subscription < ApplicationRecord
  belongs_to :company

  has_one :plan, primary_key: :preapproval_plan_id, foreign_key: :external_id, class_name: 'Plan'

  enum status: {
    pending: 'pending',
    active: 'active',
    cancelled: 'cancelled',
    expired: 'expired'
  }

  validates :company_id, presence: true
  validates :preapproval_plan_id, presence: true
  validates :status, inclusion: { in: statuses.keys }

  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }
  scope :current, -> { order(created_at: :desc).limit(1) }
  scope :active, -> { where(status: :active).limit(1) }
  scope :active_records, -> { where(status: :active) }
  scope :in_attention, -> { where(status: [:pending, :expired, :cancelled]).order(updated_at: :desc, created_at: :desc) }
  
  scope :overdue_for_notification, -> {
    where(status: :active, expiration_warning_sent_at: nil)
      .where('end_date <= ?', Date.current - 5.days)
  }
  scope :overdue_for_expiration, -> { where(status: :active).where('end_date <= ?', Date.current - 10.days) }
  
  scope :ready_to_cycle, -> { 
    joins(:company)
      .where(status: :active)
      .where(end_date: Date.current + 7.days)
      .where.not(companies: {
        payment_method: 'credit_card',
      }
    )
  }

  after_commit :sync_company_access, on: :update, if: -> { previous_changes.key?('status') }
  
  def allows_access?
    active?
  end

  def self.estimated_mrr
    active_records.sum(:transaction_amount)
  end

  def activate!
    update!(status: :active,
            start_date: Time.current,
            end_date: Time.current + 1.month,
            canceled_date: nil,
            expired_date: nil,
            expiration_warning_sent_at: nil)
  end

  def cancel!
    update!(status: :cancelled,
            canceled_date: Time.current)
  end

  def expire!
    update!(status: :expired,
            expired_date: Time.current)
  end
  
  private

  def sync_company_access
    allows_access? ? company.activate! : company.deactivate!
  end
end
