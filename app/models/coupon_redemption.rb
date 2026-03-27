class CouponRedemption < ApplicationRecord
  include Auditable

  belongs_to :coupon, counter_cache: :redemptions_count
  belongs_to :company
  belongs_to :subscription

  validates :subscription_id, uniqueness: true
  validates :original_amount, :discount_amount, :final_amount, presence: true,
                                                           numericality: { greater_than_or_equal_to: 0 }
  validates :applied_at, presence: true
  validate :company_has_no_coupon_usage_in_last_year, on: :create
  validate :final_amount_cannot_exceed_original_amount
  validate :discount_amount_cannot_exceed_original_amount

  scope :recent_for_company, ->(company, since: 1.year.ago) {
    where(company: company).where("applied_at >= ?", since)
  }

  def self.used_by_company_within_last_year?(company, reference_time: Time.current)
    return false if company.blank?

    recent_for_company(company, since: reference_time - 1.year).exists?
  end

  private

  def auditable_created_action
    "coupon.applied"
  end

  def auditable_updated_actions
    []
  end

  def auditable_deleted_action
    nil
  end

  def auditable_metadata(event_name, action:)
    {
      event: event_name.to_s,
      model: self.class.name,
      coupon_redemption_id: id,
      coupon_id: coupon_id,
      coupon_code: coupon&.code,
      company_id: company_id,
      subscription_id: subscription_id,
      original_amount: original_amount,
      discount_amount: discount_amount,
      final_amount: final_amount,
      applied_at: applied_at,
      action_source: action
    }
  end

  def company_has_no_coupon_usage_in_last_year
    reference_time = applied_at || Time.current
    return unless self.class.used_by_company_within_last_year?(company, reference_time: reference_time)

    errors.add(:base, "A empresa já utilizou um cupom nos últimos 12 meses.")
  end

  def final_amount_cannot_exceed_original_amount
    return if original_amount.blank? || final_amount.blank?
    return if final_amount <= original_amount

    errors.add(:final_amount, "não pode ser maior que o valor original")
  end

  def discount_amount_cannot_exceed_original_amount
    return if original_amount.blank? || discount_amount.blank?
    return if discount_amount <= original_amount

    errors.add(:discount_amount, "não pode ser maior que o valor original")
  end
end
