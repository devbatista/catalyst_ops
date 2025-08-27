class Assignment < ApplicationRecord
  belongs_to :user
  belongs_to :order_service

  validates :user_id, uniqueness: { scope: :order_service_id, message: "já está atribuído a esta OS" }

  validate :order_service_is_schedulable, on: :create
  validate :user_must_be_tecnico
  validate :user_availability

  scope :active, -> { joins(:order_service).where.not(order_services: { status: [:concluida, :cancelada] }) }
  scope :by_technician, ->(user_id) { where(user_id: user_id) }
  scope :by_status, ->(status) { joins(:order_service).where(order_services: { status: status }) }

  after_create :notify_technician

  after_destroy :revert_order_service_if_last_assignment
  after_destroy :notify_technician_removal

  def can_be_removed?
    !order_service.concluida?
  end

  private

  def order_service_is_schedulable
    return if order_service.blank?

    if order_service.concluida? || order_service.finalizada? || order_service.cancelada?
      errors.add(:base, "Não é possível atribuir técnicos a uma OS com status #{order_service.status.humanize}")
    end
  end

  def user_must_be_tecnico
    return unless user.present?

    unless user.can_be_tecnico?
      errors.add(:user, "deve ser um técnico")
    end
  end

  def order_service_must_allow_assignment
    return unless order_service.present?
    return if order_service.concluida? || order_service.cancelada?

    unless order_service.can_assign_technician?
      errors.add(:order_service, "não permite mais atribuições")
    end
  end

  def user_availability
    return if user.blank? || order_service.blank? || order_service.scheduled_at.blank?

    # Verificar se o técnico já tem outra OS no mesmo horário
    if conflicting_assignments.exists?
      errors.add(:user, "já possui outra OS agendada para este dia")
    end
  end

  def conflicting_assignments
    user.assignments
      .joins(:order_service)
      .where.not(order_services: { status: [:concluida, :cancelada] })
      .where.not(id: id)
      .where(order_services: {
               scheduled_at: order_service.scheduled_at.beginning_of_day..order_service.scheduled_at.end_of_day,
             })
  end

  def notify_technician
    # TechnicianMailer.assignment_created(self).deliver_later
  end

  def notify_technician_removal
    # TechnicianMailer.assignment_removed(self).deliver_later
  end

  def set_order_service_to_agendada
    order_service.agendada! if order_service.pendente?
  end

  def revert_order_service_if_last_assignment
    if order_service.users.none? && order_service.agendada?
      order_service.pendente!
    end
  end
end
