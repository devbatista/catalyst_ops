class WebhookEvent < ApplicationRecord
  PROVIDER_MERCADO_PAGO = "mercado_pago".freeze

  STATUSES = %w[received processing processed failed].freeze

  validates :provider, presence: true
  validates :event_key, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :processed, -> { where(status: "processed") }
end
