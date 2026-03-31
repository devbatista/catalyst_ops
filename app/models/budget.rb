class Budget < ApplicationRecord
  belongs_to :company
  belongs_to :client
  belongs_to :order_service, optional: true

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

  validate :company_must_match_client

  before_validation :set_company_from_client, on: :create
  before_validation :set_sequential_code, on: :create

  scope :recent, -> { order(created_at: :desc) }

  def formatted_total_value
    "R$ #{"%.2f" % total_value}"
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
end
