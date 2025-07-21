class OrderService < ApplicationRecord
  belongs_to :client
  
  has_many :assignments, dependent: :destroy
  has_many :users, through: :assignments
  has_many :service_items, dependent: :destroy
  has_many_attached :attachments
  
  enum status: { 
    agendada: 0, 
    em_andamento: 1, 
    concluida: 2, 
    cancelada: 3 
  }
  
  validates :title, :description, :status, presence: true
  validates :scheduled_at, presence: true
  
  scope :by_status, ->(status) { where(status: status) }
  scope :by_client, ->(client_id) { where(client_id: client_id) }

  def total_service_value
    service_items.sum(&:total_price)
  end
  
  def formatted_total_value
    "R$ #{'%.2f' % total_service_value}"
  end
end