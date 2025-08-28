class OrderService < ApplicationRecord
  include AttachmentValidations

  belongs_to :client
  belongs_to :company

  has_many :assignments, dependent: :destroy
  has_many :users, through: :assignments
  has_many :service_items, dependent: :destroy

  accepts_nested_attributes_for :service_items, allow_destroy: true
  accepts_nested_attributes_for :assignments, allow_destroy: true

  has_many_attached :attachments

  enum status: {
    pendente: 0,
    agendada: 1,
    em_andamento: 2,
    concluida: 3,
    cancelada: 4,
    finalizada: 5,
  }, _default: :pendente

  STATUS_ACTIONS = {
    agendada: "Agendar",
    em_andamento: "Iniciar",
    concluida: "Concluir",
    finalizada: "Finalizar",
    cancelada: "Cancelar",
  }.freeze

  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :description, presence: true, length: { minimum: 5, maximum: 1000 }
  validates :status, presence: true
  validates :scheduled_at, presence: true, if: -> { !pendente? }
  validates :client_id, presence: true
  validates :code, presence: true, uniqueness: { scope: :company_id }

  validate :scheduled_at_cannot_be_in_the_past, on: :create
  validate :must_have_technician_to_start
  validate :started_at_logic
  validate :finished_at_logic
  validate :scheduled_at_is_required_if_technicians_are_present

  scope :by_status, ->(status) { where(status: status) }
  scope :by_client, ->(client_id) { where(client_id: client_id) }
  scope :scheduled_for_today, -> { where(scheduled_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :overdue, -> { agendada.where("scheduled_at < ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_technician, ->(user_id) { joins(:users).where(users: { id: user_id }) }
  scope :unassigned, -> { left_joins(:assignments).where(assignments: { id: nil }) }

  before_validation :set_company_from_client, on: :create
  before_validation :set_sequencial_code, on: :create

  after_validation :promote_assignment_errors

  before_save :set_timestamps_on_status_change
  
  after_create :notify_client_on_create

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
    return 0 if pendente?
    return 25 if agendada?
    return 50 if em_andamento?
    return 90 if concluida?
    return 100 if finalizada?
    0
  end

  def status_color
    case status
    when "pendente" then "secondary"
    when "agendada" then "warning"
    when "em_andamento" then "info"
    when "concluida" then "success"
    when "finalizada" then "primary"
    when "cancelada" then "danger"
    end
  end

  def next_possible_statuses
    case status
    when "pendente" then ["agendada", "cancelada"]
    when "agendada" then ["em_andamento", "cancelada"]
    when "em_andamento" then ["concluida", "cancelada"]
    when "concluida" then ["finalizada"]
    when "finalizada" then []
    when "cancelada" then []
    else []
    end
  end

  def available_actions
    next_possible_statuses.map do |status_string|
      status_symbol = status_string.to_sym
      {
        label: STATUS_ACTIONS[status_symbol],
        target_status: status_symbol,
      }
    end.compact
  end

  private

  def scheduled_at_cannot_be_in_the_past
    return unless scheduled_at.present?

    if !pendente? && scheduled_at < Time.current
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

    errors.add(:started_at, "deve ser preenchido quando em andamento") if em_andamento? && started_at.blank?
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

  def notify_client_on_create
    OrderServiceMailer.notify_create(self).deliver_later
  end

  def promote_assignment_errors
    assignments.each do |assignment|
      next if assignment.valid?

      assignment.errors.each do |error|
        if error.attribute == :base && error.message.include?("data de agendamento")
          errors.add(:scheduled_at, "é obrigatório ao atribuir um técnico.")
        else
          errors.add(:base, "Houve um problema ao atribuir um técnico: #{error.full_message}")
        end
      end
    end
  end

  def scheduled_at_is_required_if_technicians_are_present
    if users.any? && scheduled_at.blank?
      errors.add(:scheduled_at, "é obrigatório quando um ou mais técnicos são atribuídos")
    end
  end
end
