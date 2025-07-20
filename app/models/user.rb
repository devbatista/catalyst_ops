class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: {
    admin: 0,
    gestor: 1,
    tecnico: 2
  }

  validates :name, presence: true

  has_many :assignments, dependent: :destroy
  has_many :order_services, through: :assignments

  scope :tecnicos, -> { where(role: :tecnico) }
  scope :gestores, -> { where(role: :gestor) }
end
