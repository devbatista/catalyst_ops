class Assignment < ApplicationRecord
  belongs_to :user
  belongs_to :order_service
  
  validates :user_id, uniqueness: { scope: :order_service_id }
  validate :user_must_be_tecnico
  
  private
  
  def user_must_be_tecnico
    errors.add(:user, 'deve ser um técnico') unless user&.tecnico?
  end
end