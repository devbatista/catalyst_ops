class ServiceItem < ApplicationRecord
  belongs_to :order_service

  validates :description, presence: true
  validates :quantity, :unit_price, presence: true, numericality: { greater_than: 0 }
  
  def total_price
    quantity * unit_price
  end

  def formatted_unit_price
    "R$ #{'%.2f' % unit_price}"
  end

  def formatted_total_price
    "R$ #{'%.2f' % total_price}"
  end
end