class Coupon < ApplicationRecord
  BENEFIT_TYPES = %w[discount trial].freeze
  DISCOUNT_TYPES = %w[percentage fixed_amount].freeze
  FREQUENCY_TYPES = %w[days weeks months].freeze

  has_many :coupon_redemptions, dependent: :restrict_with_exception

  before_validation :normalize_code

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :benefit_type, inclusion: { in: BENEFIT_TYPES }
  validates :discount_type, inclusion: { in: DISCOUNT_TYPES }, allow_blank: true
  validates :trial_frequency_type, inclusion: { in: FREQUENCY_TYPES }, allow_blank: true
  validates :discount_value, numericality: { greater_than: 0 }, allow_nil: true
  validates :max_redemptions, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :trial_frequency, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :discount_configuration_matches_benefit
  validate :trial_configuration_matches_benefit
  validate :valid_until_after_valid_from

  scope :active_records, -> { where(active: true) }
  scope :currently_valid, -> {
    now = Time.current
    where("valid_from IS NULL OR valid_from <= ?", now)
      .where("valid_until IS NULL OR valid_until >= ?", now)
  }

  def available?
    active? && started? && !expired? && redemptions_available?
  end

  def redeemable_by?(company)
    available? && !CouponRedemption.used_by_company_within_last_year?(company)
  end

  def started?
    valid_from.blank? || valid_from <= Time.current
  end

  def expired?
    valid_until.present? && valid_until < Time.current
  end

  def redemptions_available?
    max_redemptions.blank? || redemptions_count < max_redemptions
  end

  def remaining_redemptions
    return if max_redemptions.blank?

    [max_redemptions - redemptions_count, 0].max
  end

  def calculate_discount(amount)
    amount = BigDecimal(amount.to_s)
    return amount if trial?
    return BigDecimal("0") if amount <= 0

    discount =
      if percentage?
        amount * (discount_value / 100)
      else
        BigDecimal(discount_value.to_s)
      end

    [discount, amount].min
  end

  def calculate_final_amount(amount)
    amount = BigDecimal(amount.to_s)
    trial? ? BigDecimal("0") : amount - calculate_discount(amount)
  end

  def percentage?
    discount_type == "percentage"
  end

  def fixed_amount?
    discount_type == "fixed_amount"
  end

  def trial?
    benefit_type == "trial"
  end

  private

  def normalize_code
    self.code = code.to_s.upcase.strip
  end

  def discount_configuration_matches_benefit
    if trial?
      if discount_type.present? || discount_value.present?
        errors.add(:base, "Cupons de teste não devem definir desconto financeiro.")
      end
      return
    end

    if discount_type.blank? || discount_value.blank?
      errors.add(:base, "Cupons de desconto precisam informar tipo e valor do desconto.")
      return
    end

    if percentage? && discount_value.to_d > 100
      errors.add(:discount_value, "não pode ser maior que 100 para cupons percentuais")
    end
  end

  def trial_configuration_matches_benefit
    if trial?
      if trial_frequency.blank? || trial_frequency_type.blank?
        errors.add(:base, "Cupons de teste precisam informar a duração do período de teste.")
      end
      return
    end

    if trial_frequency.present? || trial_frequency_type.present?
      errors.add(:base, "Cupons de desconto não devem definir período de teste.")
    end
  end

  def valid_until_after_valid_from
    return if valid_from.blank? || valid_until.blank?
    return if valid_until >= valid_from

    errors.add(:valid_until, "deve ser posterior à data inicial")
  end
end
