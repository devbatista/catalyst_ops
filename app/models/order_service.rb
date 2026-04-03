class OrderService < ApplicationRecord
  include Auditable
  include AttachmentValidations

  belongs_to :client
  belongs_to :company

  has_many :assignments, dependent: :destroy
  has_many :users, through: :assignments, after_remove: :audit_user_unassigned
  has_many :service_items, dependent: :destroy
  has_one :budget, dependent: :nullify

  accepts_nested_attributes_for :service_items, allow_destroy: true
  accepts_nested_attributes_for :assignments, allow_destroy: true

  has_many_attached :attachments

  enum status: {
    pendente: 1,
    agendada: 2,
    em_andamento: 3,
    concluida: 4,
    finalizada: 5,
    cancelada: 6,
    atrasada: 7,
  }, _default: :pendente

  STATUS_ACTIONS = {
    agendada: "Agendar",
    em_andamento: "Iniciar",
    concluida: "Concluir",
    finalizada: "Finalizar",
    cancelada: "Cancelar",
    atrasada: "Reagendar"
  }.freeze
  DISCOUNT_TYPES = %w[none percent fixed].freeze

  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :description, presence: true, length: { minimum: 5, maximum: 1000 }
  validates :status, presence: true
  validates :scheduled_at, presence: true, if: :requires_schedule_fields?
  validates :client_id, presence: true
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :expected_end_at, presence: true, if: -> { scheduled_at.present? }
  validates :discount_type, inclusion: { in: DISCOUNT_TYPES }
  validates :discount_value, numericality: { greater_than_or_equal_to: 0 }

  validate :scheduled_at_cannot_be_in_the_past, on: [:create, :update]
  validate :expected_end_at_cannot_be_in_the_past, on: [:create, :update]
  validate :must_have_technician_to_start
  validate :started_at_logic
  validate :finished_at_logic
  validate :datetimes_fields_are_required_if_technicians_are_present
  validate :service_items_cannot_be_blank
  validate :plan_order_service_limit, on: :create
  validate :discount_value_must_be_valid_for_type
  validate :discount_reason_required_when_discount_applied

  scope :by_status, ->(status) { where(status: status) }
  scope :by_client, ->(client_id) { where(client_id: client_id) }
  scope :scheduled_for_today, -> { where(scheduled_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :to_overdue, -> { agendada.where("scheduled_at < ?", Time.current + 1.minute) }
  scope :overdue, -> { by_status(:atrasada) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_technician, ->(user_id) { joins(:users).where(users: { id: user_id }) }
  scope :unassigned, -> { left_joins(:assignments).where(assignments: { id: nil }) }
  scope :assigned, -> { joins(:assignments).distinct }
  scope :finished, -> { where(status: :finalizada) }
  scope :finished_this_month, -> { finished.where(updated_at: Time.current.all_month) }

  before_validation :set_company_from_client, on: :create
  before_validation :set_sequencial_code, on: :create
  before_validation :normalize_discount_fields

  after_validation :promote_assignment_errors

  before_save :set_timestamps_on_status_change

  after_update :notify_complete, if: -> { saved_change_to_status?(to: "concluida") }
  after_update :notify_scheduled, if: -> { saved_change_to_status?(to: "agendada") }
  after_update :notify_finished, if: -> { saved_change_to_status?(to: "finalizada") }
  after_update :notify_in_progress, if: -> { saved_change_to_status?(to: "em_andamento") }
  after_update :notify_overdue, if: -> { saved_change_to_status?(to: "atrasada") }

  def subtotal_value
    service_items.sum(&:total_price)
  end

  def discount_applied?
    discount_amount.positive?
  end

  def discount_amount
    base_value = subtotal_value.to_d
    return 0.to_d if base_value <= 0

    case discount_type
    when "percent"
      ((base_value * discount_value.to_d) / 100).round(2)
    when "fixed"
      [discount_value.to_d, base_value].min
    else
      0.to_d
    end
  end

  def total_value
    [subtotal_value.to_d - discount_amount, 0.to_d].max
  end

  def formatted_total_value
    "R$ #{"%.2f" % total_value}"
  end

  def overdue?
    atrasada?
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
    when "atrasada" then "dark"
    when "em_andamento" then "info"
    when "concluida" then "success"
    when "finalizada" then "primary"
    when "cancelada" then "danger"
    end
  end

  def next_possible_statuses
    case status
    when "pendente" then ["cancelada"]
    when "agendada" then ["em_andamento", "cancelada"]
    when "atrasada" then ["em_andamento", "cancelada"]
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

  def auditable_created_action
    "order_service.created"
  end

  def auditable_updated_actions
    changes = previous_changes.except("updated_at")
    return [] if changes.blank?

    actions = []
    actions << "order_service.status.changed" if changes.key?("status")
    actions << "order_service.updated" if changes.except("status").present?
    actions
  end

  def auditable_deleted_action
    nil
  end

  def auditable_metadata(event_name, action:)
    data = {
      event: event_name.to_s,
      model: self.class.name,
      order_service_id: id,
      code: code,
      title: title,
      status: status,
      subtotal_value: subtotal_value.to_s,
      discount_type: discount_type,
      discount_value: discount_value.to_s,
      discount_amount: discount_amount.to_s,
      total_value: total_value.to_s,
      client_id: client_id,
      company_id: company_id,
      action_source: action
    }

    return data unless event_name == :updated

    changes = previous_changes.except("updated_at")
    data[:changes] = changes if changes.present?

    if action == "order_service.status.changed" && previous_changes["status"].present?
      before_status, after_status = previous_changes["status"]
      data[:status_before] = status_name_from_change(before_status)
      data[:status_after] = status_name_from_change(after_status)
    end

    data
  end

  private

  def status_name_from_change(value)
    return value if self.class.statuses.key?(value.to_s)

    self.class.statuses.key(value.to_i) || value.to_s
  end

  def audit_user_unassigned(user)
    return if user.blank?

    Audit::Log.call(
      action: "order_service.unassigned",
      resource: self,
      metadata: {
        event: "updated",
        model: self.class.name,
        order_service_id: id,
        order_service_code: code,
        company_id: company_id,
        technician_id: user.id,
        technician_name: user.name,
        technician_email: user.email,
        action_source: "order_service.user_ids"
      }
    )
  end

  def scheduled_at_cannot_be_in_the_past
    return if will_save_change_to_status? && status_change_to_be_saved&.last == "atrasada"
    return unless scheduled_at.present?

    if requires_schedule_fields? && scheduled_at < Time.current
      errors.add(:scheduled_at, "não pode ser no passado")
    end
  end

  def expected_end_at_cannot_be_in_the_past
    return if will_save_change_to_status? && status_change_to_be_saved&.last == "atrasada"
    return unless expected_end_at.present?

    if requires_schedule_fields? && expected_end_at < Time.current
      errors.add(:expected_end_at, "não pode ser no passado")
    end

    if scheduled_at.present? && expected_end_at < scheduled_at
      errors.add(:expected_end_at, "não pode ser anterior ao horário agendado")
    end
  end

  def must_have_technician_to_start
    if status_changed? && em_andamento? && users.empty?
      errors.add(:base, "Não é possível iniciar a OS sem técnico atribuído")
    end
  end

  def service_items_cannot_be_blank
    has_blank_items = service_items.reject(&:marked_for_destruction?).any?(&:blank_item?)
    return unless has_blank_items

    errors.add(:base, "Não é possível deixar itens de serviço em branco.")
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

  def notify_complete
    notify_client_on_completion
    notify_manager_on_completion
  end

  def notify_client_on_completion
    OrderServiceMailer.notify_client_on_complete(self).deliver_later
  end

  def notify_manager_on_completion
    OrderServiceMailer.notify_manager_on_complete(self).deliver_later
  end

  def notify_scheduled
    notify_client_on_scheduled
    notify_technical_on_scheduled
  end

  def notify_client_on_scheduled
    OrderServiceMailer.notify_client_on_scheduled(self).deliver_later
  end

  def notify_technical_on_scheduled
    users.each do |user|
      OrderServiceMailer.notify_technical_on_scheduled(self, user).deliver_later
    end
  end

  def notify_finished
    notify_client_on_finished
    notify_technician_on_finished
  end

  def notify_in_progress
    OrderServiceMailer.notify_in_progress(self).deliver_later
  end

  def notify_client_on_finished
    OrderServiceMailer.notify_client_on_finished(self).deliver_later
  end

  def notify_technician_on_finished
    users.each do |user|
      OrderServiceMailer.notify_technician_on_finished(self, user).deliver_later
    end
  end

  def notify_overdue
    OrderServiceMailer.notify_overdue(self).deliver_later
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

  def datetimes_fields_are_required_if_technicians_are_present
    return if pendente? || cancelada?

    if users.any? && scheduled_at.blank? && expected_end_at.blank?
      errors.add(:scheduled_at, "é obrigatório quando um ou mais técnicos são atribuídos") if scheduled_at.blank?
      errors.add(:expected_end_at, "é obrigatório quando um ou mais técnicos são atribuídos") if expected_end_at.blank?
    end
  end

  def requires_schedule_fields?
    agendada? || em_andamento? || concluida? || finalizada? || atrasada?
  end

  def plan_order_service_limit
    unless company.can_create_order?
      errors.add(:base, "Limite de ordens de serviço atingido para o plano atual da empresa.")
    end
  end

  def normalize_discount_fields
    self.discount_type = discount_type.to_s.presence || "none"

    if discount_type == "none"
      self.discount_value = 0
      self.discount_reason = nil
    end
  end

  def discount_value_must_be_valid_for_type
    return if discount_type == "none"

    value = discount_value.to_d
    if discount_type == "percent" && value > 100
      errors.add(:discount_value, "não pode ser maior que 100%")
    end

    if discount_type == "fixed" && value > subtotal_value.to_d
      errors.add(:discount_value, "não pode ser maior que o subtotal da OS")
    end
  end

  def discount_reason_required_when_discount_applied
    return unless discount_type != "none" && discount_value.to_d.positive?
    return if discount_reason.to_s.strip.present?

    errors.add(:discount_reason, "deve ser informado quando houver desconto")
  end
end
