class User < ApplicationRecord
  include Auditable

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
  
  validate :plan_technician_limit, on: :create

  belongs_to :company, optional: true

  has_many :assignments, dependent: :restrict_with_error
  has_many :order_services, through: :assignments
  has_many :clients, foreign_key: :company_id, primary_key: :company_id, class_name: "Client"
  has_many :reports, dependent: :destroy
  has_many :support_tickets, dependent: :nullify
  has_many :assigned_support_tickets, class_name: "SupportTicket", foreign_key: :assigned_to_id, dependent: :nullify
  has_one :user_onboarding_progress, dependent: :destroy

  scope :tecnicos, -> { where(role: :tecnico).or(where(can_be_technician: true)) }
  scope :gestores, -> { where(role: :gestor) }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :created_this_month, -> { where(created_at: Time.current.all_month) }

  before_validation :normalize_name
  before_validation :normalize_phone
  before_validation :set_default_password_for_tecnico, on: :create

  after_create :send_welcome_email_for_technician, if: -> { tecnico? }

  after_update :send_welcome_email_on_activation

  def self.search(query = nil)
    if query.present?
      where("name ILIKE :q OR email ILIKE :q", q: "%#{query}%")
    else
      all
    end
  end

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
  
  def can_be_tecnico?
    tecnico? || can_be_technician?
  end

  def access_enabled?
    company.active? && active?
  end

  def send_welcome_email!(mark_as_sent: true)
    token = set_reset_password_token
    UserMailer.welcome_email(self, token).deliver_later
    update_column(:welcome_email_sent_at, Time.current) if mark_as_sent
  end

  def send_signup_confirmation_email!(expires_in: 48.hours, mark_as_sent: true)
    confirmation_token = signed_id(purpose: :signup_confirmation, expires_in: expires_in)
    UserMailer.signup_confirmation_email(self, confirmation_token).deliver_later
    update_column(:welcome_email_sent_at, Time.current) if mark_as_sent
  end

  def send_password_reset_email!
    token = set_reset_password_token
    UserMailer.reset_password_email(self, token).deliver_later
  end

  private

  def normalize_name
    self.name = name.strip.titleize if name.present?
  end

  def normalize_phone
    self.phone = phone.to_s.gsub(/\D/, "") if phone.present?
  end

  def set_default_password_for_tecnico
    if tecnico? && password.blank?
      self.password = self.password_confirmation = "alterar123"
    end
  end

  def send_welcome_email_on_activation
    if saved_change_to_active? && active? && welcome_email_sent_at.nil?
      send_welcome_email!
    end
  end

  def plan_technician_limit
    return unless company && tecnico?
    return unless company.max_technicians

    unless company.can_add_technician?
      errors.add(:base, "Limite de técnicos atingido para o plano atual da empresa.")
    end
  end

  def send_welcome_email_for_technician
    Rails.logger.info "###### Enviando email de boas-vindas para o técnico #{email} ######"
    send_welcome_email!(mark_as_sent: false)
  end

  def auditable_created_action
    tecnico? ? "technician.created" : "user.created"
  end

  def auditable_updated_actions
    actions = [ tecnico? ? "technician.updated" : "user.updated" ]
    actions << "user.role.changed" if saved_change_to_role?

    if tecnico? && saved_change_to_active?
      actions << (active? ? "technician.activated" : "technician.deactivated")
    end

    actions
  end

  def auditable_deleted_action
    "user.deleted"
  end

  def auditable_metadata(event_name, action:)
    data = {
      event: event_name.to_s,
      model: self.class.name,
      user_id: id,
      email: email,
      role: role,
      action_source: action
    }

    if event_name == :updated
      changes = previous_changes.except("updated_at")
      data[:changes] = changes if changes.present?

      if action == "user.role.changed" && previous_changes["role"].present?
        before_role, after_role = previous_changes["role"]
        data[:role_before] = role_name_from_change(before_role)
        data[:role_after] = role_name_from_change(after_role)
      end
    end

    data
  end

  def role_name_from_change(value)
    return value if self.class.roles.key?(value.to_s)

    self.class.roles.key(value.to_i) || value.to_s
  end
end
