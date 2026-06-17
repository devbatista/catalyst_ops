class OrderServiceReceivedItem < ApplicationRecord
  belongs_to :order_service

  validates :name, presence: true, length: { minimum: 2, maximum: 120 }
  validates :quantity,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 9999 },
            allow_blank: true
  validates :brand, length: { maximum: 120 }, allow_blank: true
  validates :model, length: { maximum: 120 }, allow_blank: true
  validates :serial_number, length: { maximum: 120 }, allow_blank: true
end
