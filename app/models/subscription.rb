class Subscription < ApplicationRecord
  include Auditable

  belongs_to :company
  has_many :coupon_redemptions, dependent: :restrict_with_exception

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
    activate_for!
  end

  def activate_for!(frequency: 1, frequency_type: "months", started_at: Time.current)
    period_end = MercadoPago::Subscriptions.compute_period_end(
      started_at,
      frequency: frequency,
      frequency_type: frequency_type
    )

    update!(status: :active,
            start_date: started_at,
            end_date: period_end,
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

  def auditable_created_action
    "subscription.created"
  end

  def auditable_updated_actions
    actions = []

    actions << "subscription.status.changed" if previous_changes.key?("status")

    if previous_changes.key?("external_payment_id")
      before_payment_id, after_payment_id = previous_changes["external_payment_id"]
      actions << "subscription.payment.generated" if before_payment_id.blank? && after_payment_id.present?
    end

    actions
  end

  def auditable_deleted_action
    nil
  end

  def auditable_metadata(event_name, action:)
    data = {
      event: event_name.to_s,
      model: self.class.name,
      subscription_id: id,
      company_id: company_id,
      status: status,
      transaction_amount: transaction_amount,
      payment_method: company&.payment_method,
      external_reference: external_reference,
      external_subscription_id: external_subscription_id,
      external_payment_id: external_payment_id,
      action_source: action
    }

    if event_name == :updated
      case action
      when "subscription.status.changed"
        if previous_changes["status"].present?
          before_status, after_status = previous_changes["status"]
          data[:status_before] = before_status
          data[:status_after] = after_status
        end
      when "subscription.payment.generated"
        if previous_changes["external_payment_id"].present?
          before_payment, after_payment = previous_changes["external_payment_id"]
          data[:external_payment_id_before] = before_payment
          data[:external_payment_id_after] = after_payment
        end
      end
    end

    data
  end

  def sync_company_access
    allows_access? ? company.activate! : company.deactivate!
  end
end
