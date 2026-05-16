class CompanyPdfSetting < ApplicationRecord
  DEFAULT_ACCENT_COLOR = "1F6FEB".freeze
  DOCUMENT_TYPES = %w[order_service budget].freeze

  belongs_to :company

  before_validation :normalize_accent_color

  validates :document_type, presence: true, inclusion: { in: DOCUMENT_TYPES }
  validates :accent_color,
            presence: true,
            format: {
              with: /\A[0-9A-F]{6}\z/,
              message: "deve ser uma cor hexadecimal valida"
            }
  validates :header_subtitle, length: { maximum: 80 }, allow_blank: true
  validates :document_note, length: { maximum: 160 }, allow_blank: true
  validates :footer_text, length: { maximum: 120 }, allow_blank: true

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

  def normalize_accent_color
    normalized = accent_color.to_s.strip.delete_prefix("#").upcase
    self.accent_color = normalized.presence || DEFAULT_ACCENT_COLOR
  end
end
