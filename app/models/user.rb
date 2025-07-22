class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: {
    admin: 0,
    gestor: 1,
    tecnico: 2
  }

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :role, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  belongs_to :company, optional: true

  has_many :assignments, dependent: :destroy
  has_many :order_services, through: :assignments

  scope :tecnicos, -> { where(role: :tecnico) }
  scope :gestores, -> { where(role: :gestor) }

  before_validation :normalize_name
  
  after_create :send_welcome_email, if: :persisted?

  def can_be_assigned_to_orders?
    tecnico?
  end

  def full_name
    name.titleize
  end

  def orders_count
    order_services.count
  end

  def pending_orders_count
    order_services.agendada.count
  end

  def completed_orders_count
    order_services.concluida.count
  end

  def can_manage_clients?
    admin? || gestor?
  end

  def can_create_orders?
    admin? || gestor?
  end

  private

  def normalize_name
    self.name = name.strip.titleize if name.present?
  end

  def send_welcome_email
    # UserMailer.welcome_email(self).deliver_later
  end
end
