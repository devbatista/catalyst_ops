class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: {
    admin: 0,
    gestor: 1,
    tecnico: 2,
  }

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :role, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :active, inclusion: { in: [true, false] }

  belongs_to :company, optional: true

  has_many :assignments, dependent: :destroy
  has_many :order_services, through: :assignments
  has_many :clients, foreign_key: :company_id, primary_key: :company_id, class_name: "Client"

  scope :tecnicos, -> { where(role: :tecnico) }
  scope :gestores, -> { where(role: :gestor) }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  before_validation :normalize_name
  before_validation :set_default_password_for_tecnico, on: :create

  after_create :send_welcome_email

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

  def active?
    active
  end

  def inactive?
    !active
  end

  def activate!
    update(active: true)
  end

  def inactivate!
    update(active: false)
  end

  private

  def normalize_name
    self.name = name.strip.titleize if name.present?
  end

  def set_default_password_for_tecnico
    if tecnico? && password.blank?
      self.password = self.password_confirmation = "alterar123"
    end
  end

  def send_welcome_email
    token = set_reset_password_token
    UserMailer.welcome_email(self, token).deliver_later
  end
end
