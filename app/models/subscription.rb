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
  scope :current, -> { where(status: :active).where('end_date > ?', Time.current) }

  after_commit :sync_company_access, on: :update, if: -> { previous_change.key?('status') }
  
  def allows_access?
    active?
  end

  private

  def activate!
    update!(status: :active,
            start_date: Time.current,
            end_date: Time.current + 1.month)
  end

  def cancel!
    update!(status: :cancelled,
            canceled_date: Time.current)
  end

  def sync_company_access
    allows_access? ? company.activate! : company.deactivate!
  end
end