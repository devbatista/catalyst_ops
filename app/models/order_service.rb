class OrderService < ApplicationRecord
  include Auditable
  include AttachmentValidations

  belongs_to :client
  belongs_to :company

  has_many :assignments, dependent: :destroy
  has_many :users, through: :assignments, after_remove: :audit_user_unassigned
  has_many :service_items, dependent: :destroy

  accepts_nested_attributes_for :service_items, allow_destroy: true
  accepts_nested_attributes_for :assignments, allow_destroy: true

  has_many_attached :attachments

  enum status: {
    rascunho: 0,
    pendente: 1,
    agendada: 2,
    em_andamento: 3,
    concluida: 4,
    finalizada: 5,
    cancelada: 6,
    atrasada: 7,
    rejeitada: 8,
  }, _default: :rascunho

  STATUS_ACTIONS = {
    agendada: "Agendar",
    em_andamento: "Iniciar",
    concluida: "Concluir",
    finalizada: "Finalizar",
    cancelada: "Cancelar",
    atrasada: "Reagendar",
    rejeitada: "Rejeitar"
  }.freeze

  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :description, presence: true, length: { minimum: 5, maximum: 1000 }
  validates :status, presence: true
  validates :scheduled_at, presence: true, if: :requires_schedule_fields?
  validates :client_id, presence: true
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :expected_end_at, presence: true, if: -> { scheduled_at.present? }

  validate :scheduled_at_cannot_be_in_the_past, on: [:create, :update]
  validate :expected_end_at_cannot_be_in_the_past, on: [:create, :update]
  validate :must_have_technician_to_start
  validate :started_at_logic
  validate :finished_at_logic
  validate :datetimes_fields_are_required_if_technicians_are_present
  validate :service_items_cannot_be_blank
  validate :plan_order_service_limit, on: :create

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

  after_validation :promote_assignment_errors

  before_save :set_timestamps_on_status_change

  after_update :notify_complete, if: -> { saved_change_to_status?(to: "concluida") }
  after_update :notify_scheduled, if: -> { saved_change_to_status?(to: "agendada") }
  after_update :notify_finished, if: -> { saved_change_to_status?(to: "finalizada") }
  after_update :notify_in_progress, if: -> { saved_change_to_status?(to: "em_andamento") }
  after_update :notify_overdue, if: -> { saved_change_to_status?(to: "atrasada") }
  after_update :notify_client_on_approval, if: -> { saved_change_to_approved_at? && approved_at.present? }

  def total_value
    service_items.sum(&:total_price)
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
    return 0 if rascunho? || rejeitada?
    return 0 if pendente?
    return 25 if agendada?
    return 50 if em_andamento?
    return 90 if concluida?
    return 100 if finalizada?
    0
  end

  def status_color
    case status
    when "rascunho" then "secondary"
    when "pendente" then "secondary"
    when "agendada" then "warning"
    when "atrasada" then "dark"
    when "em_andamento" then "info"
    when "concluida" then "success"
    when "finalizada" then "primary"
    when "cancelada" then "danger"
    when "rejeitada" then "danger"
    end
  end

  def next_possible_statuses
    case status
    when "rascunho" then []
    when "pendente" then ["cancelada"]
    when "agendada" then ["em_andamento", "cancelada"]
    when "atrasada" then ["em_andamento", "cancelada"]
    when "em_andamento" then ["concluida", "cancelada"]
    when "concluida" then ["finalizada"]
    when "finalizada" then []
    when "cancelada" then []
    when "rejeitada" then []
    else []
    end
  end

  def approval_token(expires_at: nil, expires_in: 1.week)
    final_expires_at = expires_at || (Time.current + expires_in).end_of_day
    ttl = final_expires_at - Time.current
    ttl = 1.second if ttl <= 0

    signed_id(purpose: :order_service_approval, expires_in: ttl)
  end

  def self.find_by_approval_token(token)
    find_signed(token, purpose: :order_service_approval)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def send_approval_request_emails!(sender_email:, expires_in: 1.week)
    sent_at = Time.current
    update_columns(
      status: self.class.statuses[:rascunho],
      approval_sent_at: sent_at,
      approved_at: nil,
      rejected_at: nil,
      rejection_reason: nil
    )

    expires_at = (sent_at + expires_in).end_of_day
    token = approval_token(expires_at: expires_at)

    OrderServiceMailer.approval_request_to_client(self, token).deliver_later
    OrderServiceMailer.approval_request_copy_to_manager(self, sender_email).deliver_later if sender_email.present?
  end

  def approval_response_deadline(expires_in: 1.week)
    return if approval_sent_at.blank?

    (approval_sent_at + expires_in).end_of_day
  end

  def approve_by_client!
    unless rascunho? || rejeitada?
      errors.add(:status, "não permite aprovação neste estado")
      return false
    end

    update!(
      status: :pendente,
      approved_at: Time.current,
      rejected_at: nil,
      rejection_reason: nil
    )
  end

  def reject_by_client!(rejection_reason:)
    unless rascunho? || rejeitada?
      errors.add(:status, "não permite rejeição neste estado")
      return false
    end

    reason = rejection_reason.to_s.strip
    if reason.blank?
      errors.add(:rejection_reason, "não pode ficar em branco")
      return false
    end

    update!(
      status: :rejeitada,
      rejected_at: Time.current,
      approved_at: nil,
      rejection_reason: reason
    )
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

  def notify_client_on_approval
    OrderServiceMailer.notify_client_on_approval(self).deliver_later
    OrderServiceMailer.notify_manager_on_approval(self).deliver_later
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
    return if rascunho? || rejeitada? || cancelada?

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
end
