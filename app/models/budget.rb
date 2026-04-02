class Budget < ApplicationRecord
  include Auditable

  belongs_to :company
  belongs_to :client
  belongs_to :order_service, optional: true
  has_many :service_items, dependent: :destroy

  accepts_nested_attributes_for :service_items, allow_destroy: true, reject_if: :all_blank

  enum status: {
    rascunho: 0,
    enviado: 1,
    aprovado: 2,
    rejeitado: 3,
    cancelado: 4
  }, _default: :rascunho

  validates :title, presence: true, length: { minimum: 3, maximum: 120 }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :status, presence: true
  validates :total_value, numericality: { greater_than_or_equal_to: 0 }
  validates :order_service_id, uniqueness: true, allow_nil: true
  validates :estimated_delivery_days,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true

  validate :company_must_match_client
  validate :service_items_cannot_be_blank

  before_validation :set_company_from_client, on: :create
  before_validation :set_sequential_code, on: :create
  before_validation :set_total_value_from_service_items

  scope :recent, -> { order(created_at: :desc) }

  def formatted_total_value
    "R$ #{"%.2f" % total_value}"
  end

  def editable?
    rascunho? || rejeitado?
  end

  def approval_token(expires_at: nil, expires_in: 1.week)
    final_expires_at = expires_at || (Time.current + expires_in).end_of_day
    ttl = final_expires_at - Time.current
    ttl = 1.second if ttl <= 0

    signed_id(purpose: :budget_approval, expires_in: ttl)
  end

  def approval_expires_at
    valid_until&.end_of_day || (Time.current + 1.week).end_of_day
  end

  def self.find_by_approval_token(token)
    find_signed(token, purpose: :budget_approval)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def send_for_approval!
    update!(
      status: :enviado,
      approval_sent_at: Time.current,
      approved_at: nil,
      rejected_at: nil,
      rejection_reason: nil
    )
  end

  def approve_and_create_order_service!(approver_role:)
    unless rascunho? || enviado? || rejeitado? || aprovado?
      errors.add(:status, "não permite aprovação neste estado")
      raise ActiveRecord::RecordInvalid, self
    end

    Cmd::Budgets::ApproveAndCreateOrderService.new(
      budget: self,
      approver_role: approver_role
    ).call
  end

  def reject!(rejection_reason:)
    unless rascunho? || enviado? || rejeitado?
      errors.add(:status, "não permite rejeição neste estado")
      raise ActiveRecord::RecordInvalid, self
    end

    reason = rejection_reason.to_s.strip
    if reason.blank?
      errors.add(:rejection_reason, "não pode ficar em branco")
      raise ActiveRecord::RecordInvalid, self
    end

    update!(
      status: :rejeitado,
      rejected_at: Time.current,
      approved_at: nil,
      rejection_reason: reason
    )
  end

  private

  def auditable_created_action
    "budget.created"
  end

  def auditable_updated_actions
    changes = previous_changes.except("updated_at")
    return [] if changes.blank?

    actions = []

    if changes.key?("status")
      before_status, after_status = changes["status"]
      before_name = status_name_from_change(before_status)
      after_name = status_name_from_change(after_status)

      status_action =
        case after_name
        when "enviado"
          "budget.sent_for_approval"
        when "aprovado"
          "budget.approved"
        when "rejeitado"
          "budget.rejected"
        else
          "budget.status.changed"
        end

      actions << status_action unless before_name == after_name
    end

    non_status_changes = changes.except("status")
    actions << "budget.updated" if non_status_changes.present?
    actions
  end

  def auditable_deleted_action
    nil
  end

  def auditable_metadata(event_name, action:)
    data = {
      event: event_name.to_s,
      model: self.class.name,
      budget_id: id,
      code: code,
      title: title,
      status: status,
      total_value: total_value.to_s,
      valid_until: valid_until&.to_s,
      estimated_delivery_days: estimated_delivery_days,
      client_id: client_id,
      company_id: company_id,
      order_service_id: order_service_id,
      action_source: action
    }

    return data unless event_name == :updated

    changes = previous_changes.except("updated_at")
    data[:changes] = changes if changes.present?

    if changes["status"].present?
      before_status, after_status = changes["status"]
      data[:status_before] = status_name_from_change(before_status)
      data[:status_after] = status_name_from_change(after_status)
    end

    data
  end

  def set_company_from_client
    self.company_id ||= client&.company_id
  end

  def set_sequential_code
    return if code.present? || company_id.blank?

    last_code = self.class.where(company_id: company_id).maximum(:code) || 0
    self.code = last_code + 1
  end

  def company_must_match_client
    return if company.blank? || client.blank?
    return if company_id == client.company_id

    errors.add(:company_id, "deve ser a mesma empresa do cliente")
  end

  def set_total_value_from_service_items
    items = service_items.reject(&:marked_for_destruction?)
    return if items.blank?

    self.total_value = items.sum do |item|
      item.quantity.to_i * item.unit_price.to_d
    end
  end

  def service_items_cannot_be_blank
    has_blank_items = service_items.reject(&:marked_for_destruction?).any?(&:blank_item?)
    return unless has_blank_items

    errors.add(:base, "Não é possível deixar itens de serviço em branco.")
  end

  def status_name_from_change(value)
    return value if self.class.statuses.key?(value.to_s)

    self.class.statuses.key(value.to_i) || value.to_s
  end
end
