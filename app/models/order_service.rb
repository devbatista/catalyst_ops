class OrderService < ApplicationRecord
  include AttachmentValidations
  
  belongs_to :client
  belongs_to :company

  has_many :assignments, dependent: :destroy
  has_many :users, through: :assignments
  has_many :service_items, dependent: :destroy

  accepts_nested_attributes_for :service_items, allow_destroy: true

  has_many_attached :attachments

  enum status: {
    agendada: 0,
    em_andamento: 1,
    concluida: 2,
    cancelada: 3,
    finalizada: 4,
  }

  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :description, presence: true, length: { minimum: 5, maximum: 1000 }
  validates :status, presence: true
  validates :scheduled_at, presence: true
  validates :client_id, presence: true
  validates :code, presence: true, uniqueness: { scope: :company_id }

  validate :scheduled_at_cannot_be_in_the_past, on: :create
  validate :must_have_technician_to_start
  validate :started_at_logic
  validate :finished_at_logic
  validate :cannot_assign_if_completed

  scope :by_status, ->(status) { where(status: status) }
  scope :by_client, ->(client_id) { where(client_id: client_id) }
  scope :scheduled_for_today, -> { where(scheduled_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :overdue, -> { agendada.where("scheduled_at < ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_technician, ->(user_id) { joins(:users).where(users: { id: user_id }) }
  scope :unassigned, -> { left_joins(:assignments).where(assignments: { id: nil }) }

  before_validation :set_company_from_client, on: :create
  before_validation :set_sequencial_code, on: :create

  before_save :set_timestamps_on_status_change

  after_update :notify_client_on_completion, if: :saved_change_to_status?

  def total_value
    service_items.sum(&:total_price)
  end

  def formatted_total_value
    "R$ #{"%.2f" % total_value}"
  end

  def overdue?
    agendada? && scheduled_at < Time.current
  end

  def can_be_started?
    agendada? && users.any?
  end

  def can_be_completed?
    em_andamento? && service_items.any?
  end

  def can_be_cancelled?
    !concluida?
  end

  def can_assign_technician?
    !concluida? && !cancelada?
  end

  def duration_in_hours
    return 0 unless started_at && finished_at

    ((finished_at - started_at) / 1.hour).round(2)
  end

  def technician_names
    users.map(&:name).join(", ")
  end

  def progress_percentage
    return 0 if agendada?
    return 50 if em_andamento?
    return 90 if concluida?
    return 100 if finalizada?
    0
  end

  def status_color
    case status
    when "agendada" then "warning"
    when "em_andamento" then "info"
    when "concluida" then "success"
    when "finalizada" then "primary"
    when "cancelada" then "danger"
    end
  end

  def next_possible_statuses
    case status
    when "agendada" then ["em_andamento", "cancelada"]
    when "em_andamento" then ["concluida", "cancelada"]
    when "concluida" then ["finalizada"]
    when "finalizada" then []
    when "cancelada" then []
    else []
    end
  end

  private

  def scheduled_at_cannot_be_in_the_past
    return unless scheduled_at.present?

    if scheduled_at < Time.current
      errors.add(:scheduled_at, "não pode ser no passado")
    end
  end

  def must_have_technician_to_start
    if status_changed? && em_andamento? && users.empty?
      errors.add(:base, "Não é possível iniciar a OS sem técnico atribuído")
    end
  end

  def started_at_logic
    return unless started_at.present?

    if em_andamento? && started_at.blank?
      errors.add(:started_at, "deve ser preenchido quando em andamento")
    end

    if started_at.present? && scheduled_at.present? && started_at < scheduled_at
      errors.add(:started_at, "não pode ser anterior ao agendamento")
    end
  end

  def finished_at_logic
    return unless finished_at.present?

    if concluida? && finished_at.blank?
      errors.add(:finished_at, "deve ser preenchido quando concluído")
    end

    if finished_at.present? && started_at.present? && finished_at < started_at
      errors.add(:finished_at, "não pode ser anterior ao início")
    end
  end

  def cannot_assign_if_completed
    if concluida? && assignments.any?
      last_created_at = assignments.last.created_at
      if last_created_at.present? && updated_at.present? && last_created_at > updated_at
        errors.add(:base, "Não é possível atribuir técnicos a uma OS concluída")
      end
    end
  end

  def set_timestamps_on_status_change
    if status_changed?
      case status
      when "em_andamento"
        self.started_at = Time.current if started_at.blank?
      when "concluida"
        self.finished_at = Time.current if finished_at.blank?
      end
    end
  end

  def set_company_from_client
    self.company_id ||= client.company_id if client.present?
  end

  def set_sequencial_code
    return if code.present? || company_id.blank?

    last_code = OrderService.where(company_id: company_id).maximum(:code) || 0
    self.code = last_code + 1
  end

  def notify_client_on_completion
    # ClientMailer.order_completed(self).deliver_later if concluida?
  end
end
