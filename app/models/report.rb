class Report < ApplicationRecord
  belongs_to :user
  belongs_to :company

  enum status: {
    pending: "pending",
    processing: "processing",
    finished: "finished",
    failed: "failed",
  }, _prefix: true

  enum report_type: {
    clients: "clients",
    technicians: "technicians",
    service_orders: "service_orders",
  }, _prefix: true

  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :report_type, presence: true
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :generated_at, presence: true, if: -> { finished? }
  validates :file, presence: true, if: -> { finished? }
  validates :error_message, length: { maximum: 1000 }, allow_blank: true

  serialize :filters, JSON

  def status_human
    {
      "pending" => "Pendente",
      "processing" => "Processando",
      "finished" => "Finalizado",
      "failed" => "Falhou",
    }[status] || status
  end
end
