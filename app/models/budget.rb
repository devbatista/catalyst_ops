class Budget < ApplicationRecord
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

    Budgets::ApproveAndCreateOrderService.call(budget: self, approver_role: approver_role)
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
end
