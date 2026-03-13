class SupportTicket < ApplicationRecord
  belongs_to :company
  belongs_to :user
  belongs_to :order_service, optional: true
  belongs_to :assigned_to, class_name: "User", optional: true

  has_many :support_messages, dependent: :destroy
  has_many_attached :attachments

  enum category: {
    duvida: 0,
    problema_tecnico: 1,
    financeiro: 2,
    sugestao: 3,
    outros: 4
  }

  enum impact: {
    baixo: 0,
    medio: 1,
    alto: 2,
    bloqueante: 3
  }

  enum status: {
    aberto: 0,
    em_andamento: 1,
    aguardando_cliente: 2,
    resolvido: 3,
    fechado: 4,
    cancelado: 5
  }

  enum priority: {
    baixa: 0,
    normal: 1,
    alta: 2,
    critica: 3
  }

  validates :subject, presence: true, length: { maximum: 200 }
  validates :description, presence: true
  validates :category, :impact, :status, :priority, presence: true

  scope :recent, -> { order(last_reply_at: :desc, created_at: :desc) }
  scope :by_company, ->(company_id) { where(company_id: company_id) }
  scope :open_status, -> { where(status: [:aberto, :em_andamento, :aguardando_cliente]) }

  before_create :set_initial_last_reply_at

  before_update :prevent_status_change_if_closed_or_cancelled

  def add_message!(user:, body:, attachments: [])
    raise "Ticket fechado ou cancelado não pode ser reaberto, caso necessário abra um novo ticket" if fechado? || cancelado?

    transaction do
      message = support_messages.create!(
        user: user,
        body: body,
        attachments: attachments
      )
      
      apply_status_rules_after_message_from(user)
      apply_assignment_rules_after_message_from(user)
      
      save!
      message
    end
  end

  def mark_as_resolved!
    update!(status: :resolvido)
  end

  def mark_as_closed!
    update!(status: :fechado)
  end

  private

  def apply_status_rules_after_message_from(user)
    current = status.to_sym
  
    if user.admin?
      case current
      when :aberto, :em_andamento
        self.status = :aguardando_cliente
      else
        # :aguardando_cliente, :resolvido, :fechado, :cancelado → mantém
      end
    else
      case current
      when :aberto, :em_andamento, :aguardando_cliente
        self.status = :em_andamento
      when :resolvido
        self.status = :em_andamento
      end
    end
  end

  def apply_assignment_rules_after_message_from(user)
    return unless user.admin?
    
    self.assigned_to ||= user
  end

  def set_initial_last_reply_at
    self.last_reply_at ||= Time.current
  end

  def prevent_status_change_if_closed_or_cancelled
    if status_changed? && status_was.in?(%w[fechado cancelado])
      errors.add(:status, "Não pode ser alterado em tickets fechado ou cancelado")
      throw(:abort)
    end
  end
end