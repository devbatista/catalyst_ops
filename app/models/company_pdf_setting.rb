class CompanyPdfSetting < ApplicationRecord
  DEFAULT_ACCENT_COLOR = "1F6FEB".freeze
  DOCUMENT_TYPES = %w[order_service budget].freeze

  belongs_to :company
  has_one_attached :logo

  before_validation :normalize_colors

  validates :document_type, presence: true, inclusion: { in: DOCUMENT_TYPES }
  validates :accent_color,
            presence: true,
            format: {
              with: /\A[0-9A-F]{6}\z/,
              message: "deve ser uma cor hexadecimal valida"
            }
  validates :header_text_color,
            format: {
              with: /\A[0-9A-F]{6}\z/,
              message: "deve ser uma cor hexadecimal valida"
            },
            allow_blank: true
  validates :header_subtitle, length: { maximum: 80 }, allow_blank: true
  validates :document_note, length: { maximum: 160 }, allow_blank: true
  validates :footer_text, length: { maximum: 120 }, allow_blank: true
  validates :logo,
            content_type: ["image/png", "image/jpeg", "image/jpg"],
            size: { less_than: 2.megabytes, message: "deve ter menos de 2MB" }

  def order_service?
    document_type == "order_service"
  end

  def budget?
    document_type == "budget"
  end

  def enabled?
    customization_enabled?
  end

  private

  def normalize_colors
    self.accent_color = normalize_hex_color(accent_color).presence || DEFAULT_ACCENT_COLOR
    self.header_text_color = normalize_hex_color(header_text_color)
  end

  def normalize_hex_color(value)
    value.to_s.strip.delete_prefix("#").upcase.presence
  end
end
