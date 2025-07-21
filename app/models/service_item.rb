class ServiceItem < ApplicationRecord
  belongs_to :order_service
  
  validates :description, presence: true, length: { minimum: 5, maximum: 200 }
  validates :quantity, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 9999.99 }
  validates :unit_price, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 999999.99 }
  validate :cannot_edit_if_order_completed
  
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
    quantity % 1 == 0 ? quantity.to_i.to_s : quantity.to_s
  end
  
  def can_be_edited?
    !order_service.concluida?
  end
  
  def can_be_deleted?
    !order_service.concluida?
  end
  
  private
  
  def cannot_edit_if_order_completed
    if order_service&.concluida? && (changed? || new_record?)
      errors.add(:base, 'Não é possível modificar itens de uma OS concluída')
    end
  end
  
  def calculate_total
    # Este método pode ser usado para cálculos adicionais se necessário
    # Por enquanto, total_price já faz o cálculo
  end
  
  def update_order_service_total
    order_service.touch if order_service.present?
  end
end