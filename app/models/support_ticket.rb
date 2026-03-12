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

  private

  def set_initial_last_reply_at
    self.last_reply_at ||= Time.current
  end
end