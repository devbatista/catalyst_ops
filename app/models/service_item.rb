class ServiceItem < ApplicationRecord
  belongs_to :order_service

  validates :description, presence: true
  validates :quantity, :unit_price, presence: true, numericality: { greater_than: 0 }
  
  def total_price
    quantity * unit_price
  end
end