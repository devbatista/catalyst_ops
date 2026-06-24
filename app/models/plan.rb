class Plan < ApplicationRecord
  include Auditable

  has_many :subscriptions, primary_key: :external_id, foreign_key: :preapproval_plan_id, class_name: 'Subscription'
  
  validates :name, :reason, :status,
            :external_id, :external_reference,
            :frequency, :frequency_type,
            :transaction_amount,
            presence: true
  validates :external_id, :external_reference, uniqueness: true
  validates :frequency, numericality: { only_integer: true, greater_than: 0 }
  validates :transaction_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :paid_plan_must_have_positive_amount

  STATUSES = %w[active inactive].freeze
  validates :status, inclusion: { in: STATUSES }

  scope :paid, -> { where(free: false) }

  def paid?
    !free?
  end

  private

  def paid_plan_must_have_positive_amount
    return if free? || transaction_amount.to_d.positive?

    errors.add(:transaction_amount, "deve ser maior que 0 para planos pagos")
  end

  def auditable_created_action
    "plan.created"
  end

  def auditable_updated_actions
    changes = previous_changes.except("updated_at")
    return [] if changes.blank?

    [ "plan.updated" ]
  end

  def auditable_deleted_action
    "plan.deleted"
  end

  def auditable_metadata(event_name, action:)
    data = {
      event: event_name.to_s,
      model: self.class.name,
      plan_id: id,
      name: name,
      reason: reason,
      status: status,
      external_id: external_id,
      external_reference: external_reference,
      frequency: frequency,
      frequency_type: frequency_type,
      transaction_amount: transaction_amount,
      max_technicians: max_technicians,
      max_orders: max_orders,
      max_budgets: max_budgets,
      support_level: support_level,
      free: free,
      action_source: action
    }

    if event_name == :updated
      changes = previous_changes.except("updated_at")
      data[:changes] = changes if changes.present?
    end

    data
  end
end
