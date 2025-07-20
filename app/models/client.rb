class Client < ApplicationRecord
  validates :name, :document, :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  has_many :order_services, dependent: :destroy
end