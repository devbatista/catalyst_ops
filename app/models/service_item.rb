class ServiceItem < ApplicationRecord
  belongs_to :order_service, optional: true
  belongs_to :budget, optional: true

  with_options unless: :blank_item? do
    validates :description, presence: true, length: { minimum: 5, maximum: 200 }
    validates :quantity,
              presence: true,
              numericality: {
                only_integer: true,
                greater_than: 0,
                less_than_or_equal_to: 9999
              }
    validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  end

  validate :cannot_edit_if_order_completed
  validate :must_belong_to_order_service_or_budget

  before_save :calculate_total

  after_save :update_order_service_total

  after_destroy :update_order_service_total

  def total_price
    quantity * unit_price
  end

  def formatted_unit_price
    "R$ #{'%.2f' % unit_price}"
  end

  def formatted_total_price
    "R$ #{'%.2f' % total_price}"
  end

  def formatted_quantity
    quantity.to_i.to_s
  end

  def can_be_edited?
    return !order_service.concluida? if order_service.present?
    return budget.editable? if budget.present?

    false
  end

  def can_be_deleted?
    can_be_edited?
  end

  def unit_price=(value)
    super(normalize_decimal_input(value))
  end

  def blank_item?
    description.blank? && quantity.blank? && unit_price.blank?
  end

  private

  def normalize_decimal_input(value)
    return value unless value.is_a?(String)

    sanitized = value.strip
    return sanitized if sanitized.blank?

    sanitized = sanitized.gsub(/[^\d,.\-]/, "")
    return value if sanitized.blank?

    if sanitized.include?(",")
      sanitized = sanitized.gsub(".", "").tr(",", ".")
    elsif sanitized.count(".") > 1
      sanitized = sanitized.delete(".")
    end

    BigDecimal(sanitized)
  rescue ArgumentError
    value
  end

  def cannot_edit_if_order_completed
    if order_service&.concluida? && (changed? || new_record?)
      errors.add(:base, 'Não é possível modificar itens de uma OS concluída')
    end
  end

  def must_belong_to_order_service_or_budget
    return if order_service.present? || budget.present?

    errors.add(:base, "Item de serviço deve pertencer a uma OS ou orçamento")
  end

  def calculate_total
    # Este método pode ser usado para cálculos adicionais se necessário
    # Por enquanto, total_price já faz o cálculo
  end

  def update_order_service_total
    order_service.touch if order_service.present?
    budget.touch if budget.present?
  end
end
