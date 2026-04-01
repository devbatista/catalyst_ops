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
  scope :scheduled_for_cancellation_due, -> {
    where(status: :active, cancel_at_period_end: true).where('cancel_effective_on <= ?', Date.current)
  }
  
  scope :ready_to_cycle, -> { 
    joins(:company)
      .where(status: :active)
      .where(cancel_at_period_end: false)
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
            cancel_at_period_end: false,
            cancel_requested_at: nil,
            cancel_effective_on: nil,
            cancel_reason: nil,
            expired_date: nil,
            expiration_warning_sent_at: nil)
  end

  def cancel!
    update!(status: :cancelled,
            canceled_date: Time.current,
            cancel_at_period_end: false)
  end

  def expire!
    update!(status: :expired,
            expired_date: Time.current)
  end

  def schedule_cancellation!(reason: nil)
    unless active?
      errors.add(:base, "Apenas assinaturas ativas podem ser agendadas para cancelamento.")
      raise ActiveRecord::RecordInvalid, self
    end

    if cancel_at_period_end?
      errors.add(:base, "A assinatura já está agendada para cancelamento.")
      raise ActiveRecord::RecordInvalid, self
    end

    effective_on = end_date.presence || Date.current

    update!(
      cancel_at_period_end: true,
      cancel_requested_at: Time.current,
      cancel_effective_on: effective_on,
      cancel_reason: reason
    )
  end

  def resume_cancellation!
    unless active?
      errors.add(:base, "Apenas assinaturas ativas podem reativar renovação.")
      raise ActiveRecord::RecordInvalid, self
    end

    unless cancel_at_period_end?
      errors.add(:base, "Não existe cancelamento agendado para reativar.")
      raise ActiveRecord::RecordInvalid, self
    end

    update!(
      cancel_at_period_end: false,
      cancel_requested_at: nil,
      cancel_effective_on: nil,
      cancel_reason: nil
    )
  end

  def cancel_due?(reference_date: Date.current)
    cancel_at_period_end? && cancel_effective_on.present? && cancel_effective_on <= reference_date
  end

  def finalize_scheduled_cancellation!(reference_date: Date.current)
    return false unless cancel_due?(reference_date: reference_date)

    update!(
      status: :cancelled,
      canceled_date: Time.current,
      cancel_at_period_end: false,
      cancel_requested_at: nil,
      cancel_effective_on: nil,
      cancel_reason: nil
    )
  end
  
  private

  def auditable_created_action
    "subscription.created"
  end

  def auditable_updated_actions
    actions = []

    actions << "subscription.status.changed" if previous_changes.key?("status")
    actions << "subscription.cancellation.scheduled" if cancellation_scheduled?
    actions << "subscription.cancellation.resumed" if cancellation_resumed?

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
      when "subscription.cancellation.scheduled", "subscription.cancellation.resumed"
        if previous_changes["cancel_at_period_end"].present?
          before_value, after_value = previous_changes["cancel_at_period_end"]
          data[:cancel_at_period_end_before] = before_value
          data[:cancel_at_period_end_after] = after_value
        end

        data[:cancel_requested_at] = cancel_requested_at
        data[:cancel_effective_on] = cancel_effective_on
        data[:cancel_reason] = cancel_reason
      end
    end

    data
  end

  def cancellation_scheduled?
    before_value, after_value = previous_changes["cancel_at_period_end"]
    before_value == false && after_value == true
  end

  def cancellation_resumed?
    before_value, after_value = previous_changes["cancel_at_period_end"]
    before_value == true && after_value == false && active?
  end

  def sync_company_access
    allows_access? ? company.activate! : company.deactivate!
  end
end
