class Subscription < ApplicationRecord
  include Auditable

  belongs_to :company
  has_many :coupon_redemptions, dependent: :restrict_with_exception

  has_one :plan, primary_key: :preapproval_plan_id, foreign_key: :external_id, class_name: 'Plan'

  enum status: {
    pending: 'pending',
    active: 'active',
    cancelled: 'cancelled',
    expired: 'expired'
  }

  validates :company_id, presence: true
  validates :preapproval_plan_id, presence: true
  validates :status, inclusion: { in: statuses.keys }

  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }
  scope :current, -> { order(created_at: :desc).limit(1) }
  scope :active, -> { where(status: :active).limit(1) }
  scope :active_records, -> { where(status: :active) }
  scope :in_attention, -> { where(status: [:pending, :expired, :cancelled]).order(updated_at: :desc, created_at: :desc) }
  
  scope :overdue_for_notification, -> {
    where(status: :active, expiration_warning_sent_at: nil)
      .where('end_date <= ?', Date.current - 5.days)
  }
  scope :overdue_for_expiration, -> { where(status: :active).where('end_date <= ?', Date.current - 10.days) }
  
  scope :ready_to_cycle, -> { 
    joins(:company)
      .where(status: :active)
      .where(end_date: Date.current + 7.days)
      .where.not(companies: {
        payment_method: 'credit_card',
      }
    )
  }

  PLAN_TIER_BASIC = "basic".freeze
  PLAN_TIER_PROFESSIONAL = "professional".freeze
  PLAN_TIER_ENTERPRISE = "enterprise".freeze

  UPGRADE_RULES = {
    PLAN_TIER_BASIC => [PLAN_TIER_PROFESSIONAL, PLAN_TIER_ENTERPRISE].freeze,
    PLAN_TIER_PROFESSIONAL => [PLAN_TIER_ENTERPRISE].freeze,
    PLAN_TIER_ENTERPRISE => [].freeze
  }.freeze

  after_commit :sync_company_access, on: :update, if: -> { previous_changes.key?('status') }
  
  def allows_access?
    active?
  end

  def self.estimated_mrr
    active_records.sum(:transaction_amount)
  end

  def activate!
    activate_for!
  end

  def activate_for!(frequency: 1, frequency_type: "months", started_at: Time.current)
    period_end = MercadoPago::Subscriptions.compute_period_end(
      started_at,
      frequency: frequency,
      frequency_type: frequency_type
    )

    update!(status: :active,
            start_date: started_at,
            end_date: period_end,
            canceled_date: nil,
            expired_date: nil,
            expiration_warning_sent_at: nil)
  end

  def cancel!
    update!(status: :cancelled,
            canceled_date: Time.current)
  end

  def expire!
    update!(status: :expired,
            expired_date: Time.current)
  end

  def can_upgrade_to_plan?(target_plan)
    return false if target_plan.blank? || plan.blank?

    current_tier = self.class.plan_tier_from_name(plan.name)
    target_tier = self.class.plan_tier_from_name(target_plan.name)
    return false if current_tier.blank? || target_tier.blank?

    UPGRADE_RULES.fetch(current_tier, []).include?(target_tier)
  end

  def upgradeable_plans
    return [] if plan.blank?

    current_tier = self.class.plan_tier_from_name(plan.name)
    allowed_tiers = UPGRADE_RULES.fetch(current_tier, [])
    return [] if allowed_tiers.blank?

    Plan.where(status: "active").select do |candidate|
      allowed_tiers.include?(self.class.plan_tier_from_name(candidate.name))
    end
  end

  def upgrade_to!(target_plan)
    unless can_upgrade_to_plan?(target_plan)
      errors.add(:base, "Upgrade não permitido para o plano selecionado.")
      raise ActiveRecord::RecordInvalid, self
    end

    proration = calculate_proration_for_upgrade(target_plan)

    transaction do
      merged_payload = (raw_payload || {}).deep_dup
      merged_payload["plan_upgrade"] = {
        "from_plan_name" => plan&.name,
        "to_plan_name" => target_plan.name,
        "from_amount" => proration[:from_amount].to_s("F"),
        "to_amount" => target_plan.transaction_amount.to_d.to_s("F"),
        "difference_amount" => proration[:difference_amount].to_s("F"),
        "proration_amount" => proration[:proration_amount].to_s("F"),
        "proration_ratio" => proration[:proration_ratio].to_s("F"),
        "cycle_days_total" => proration[:cycle_days_total],
        "cycle_days_remaining" => proration[:cycle_days_remaining],
        "billing_mode" => "immediate_prorata",
        "effective_on" => Date.current.to_s,
        "computed_at" => Time.current.iso8601
      }

      update!(
        preapproval_plan_id: target_plan.external_id,
        reason: target_plan.reason,
        transaction_amount: target_plan.transaction_amount,
        raw_payload: merged_payload
      )
      company.update!(plan: target_plan)
    end

    proration
  end

  def register_pending_upgrade!(target_plan:, proration:, payment_id:)
    payload = safe_raw_payload_hash
    payload["plan_upgrade"] = {
      "status" => "pending_payment",
      "requested_at" => Time.current.iso8601,
      "payment_id" => payment_id.to_s,
      "target_plan_id" => target_plan.id,
      "target_plan_external_id" => target_plan.external_id,
      "target_plan_name" => target_plan.name,
      "target_plan_reason" => target_plan.reason,
      "target_transaction_amount" => target_plan.transaction_amount.to_d.to_s("F"),
      "from_plan_name" => plan&.name,
      "from_amount" => proration[:from_amount].to_s("F"),
      "to_amount" => proration[:to_amount].to_s("F"),
      "difference_amount" => proration[:difference_amount].to_s("F"),
      "proration_amount" => proration[:proration_amount].to_s("F"),
      "proration_ratio" => proration[:proration_ratio].to_s("F"),
      "cycle_days_total" => proration[:cycle_days_total],
      "cycle_days_remaining" => proration[:cycle_days_remaining],
      "billing_mode" => "immediate_prorata"
    }

    update!(raw_payload: payload)
  end

  def apply_pending_upgrade_if_payment_confirmed!(payment_id:)
    payload = safe_raw_payload_hash
    upgrade = payload["plan_upgrade"]
    return false if upgrade.blank?
    return false unless upgrade["status"] == "pending_payment"
    return false unless upgrade["payment_id"].to_s == payment_id.to_s

    target_plan = Plan.find_by(external_id: upgrade["target_plan_external_id"].to_s)
    return false if target_plan.blank?

    transaction do
      update!(
        preapproval_plan_id: target_plan.external_id,
        reason: target_plan.reason,
        transaction_amount: target_plan.transaction_amount
      )
      company.update!(plan: target_plan)

      payload_after = safe_raw_payload_hash
      payload_after["plan_upgrade"] = upgrade.merge(
        "status" => "applied",
        "applied_at" => Time.current.iso8601
      )
      update!(raw_payload: payload_after)
    end

    true
  end

  def proration_for_upgrade(target_plan, reference_date: Date.current)
    calculate_proration_for_upgrade(target_plan, reference_date: reference_date)
  end

  def pending_upgrade_for_payment?(payment_id:)
    upgrade = safe_raw_payload_hash["plan_upgrade"]
    return false if upgrade.blank?

    upgrade["status"] == "pending_payment" && upgrade["payment_id"].to_s == payment_id.to_s
  end

  def has_pending_upgrade_request?
    upgrade = safe_raw_payload_hash["plan_upgrade"]
    upgrade.present? && upgrade["status"] == "pending_payment"
  end

  def pending_upgrade_data
    upgrade = safe_raw_payload_hash["plan_upgrade"]
    return nil if upgrade.blank?
    return nil unless upgrade["status"] == "pending_payment"

    upgrade
  end

  def mark_pending_upgrade_as!(payment_id:, status:, reason: nil)
    payload = safe_raw_payload_hash
    upgrade = payload["plan_upgrade"]
    return false if upgrade.blank?
    return false unless upgrade["status"] == "pending_payment"
    return false unless upgrade["payment_id"].to_s == payment_id.to_s

    payload["plan_upgrade"] = upgrade.merge(
      "status" => status.to_s,
      "updated_at" => Time.current.iso8601,
      "failure_reason" => reason.presence
    ).compact

    update!(raw_payload: payload)
    true
  end
  
  private

  def self.plan_tier_from_name(name)
    normalized = I18n.transliterate(name.to_s).downcase
    return PLAN_TIER_BASIC if normalized.include?("basico") || normalized.include?("basic")
    return PLAN_TIER_PROFESSIONAL if normalized.include?("profissional") || normalized.include?("professional")
    return PLAN_TIER_ENTERPRISE if normalized.include?("enterprise")

    nil
  end

  def calculate_proration_for_upgrade(target_plan, reference_date: Date.current)
    from_amount = (transaction_amount.presence || plan&.transaction_amount).to_d
    to_amount = target_plan.transaction_amount.to_d
    difference_amount = (to_amount - from_amount)
    difference_amount = 0.to_d if difference_amount.negative?

    cycle_days_total = cycle_days_total(reference_date)
    cycle_days_remaining = cycle_days_remaining(reference_date)
    proration_ratio = cycle_days_remaining.to_d / cycle_days_total.to_d
    proration_amount = (difference_amount * proration_ratio).round(2)

    {
      from_amount: from_amount,
      to_amount: to_amount,
      difference_amount: difference_amount,
      proration_amount: proration_amount,
      proration_ratio: proration_ratio.round(6),
      cycle_days_total: cycle_days_total,
      cycle_days_remaining: cycle_days_remaining
    }
  end

  def cycle_days_total(reference_date = Date.current)
    return 30 unless start_date.present? && end_date.present?

    total = (end_date.to_date - start_date.to_date).to_i
    return 30 if total <= 0

    total
  end

  def cycle_days_remaining(reference_date = Date.current)
    return cycle_days_total(reference_date) unless end_date.present?

    remaining = (end_date.to_date - reference_date.to_date).to_i
    return 0 if remaining.negative?

    remaining
  end

  def safe_raw_payload_hash
    raw_payload.is_a?(Hash) ? raw_payload.deep_dup : {}
  end

  def auditable_created_action
    "subscription.created"
  end

  def auditable_updated_actions
    actions = []

    actions << "subscription.status.changed" if previous_changes.key?("status")

    if previous_changes.key?("external_payment_id")
      before_payment_id, after_payment_id = previous_changes["external_payment_id"]
      actions << "subscription.payment.generated" if before_payment_id.blank? && after_payment_id.present?
    end

    actions
  end

  def auditable_deleted_action
    nil
  end

  def auditable_metadata(event_name, action:)
    data = {
      event: event_name.to_s,
      model: self.class.name,
      subscription_id: id,
      company_id: company_id,
      status: status,
      transaction_amount: transaction_amount,
      payment_method: company&.payment_method,
      external_reference: external_reference,
      external_subscription_id: external_subscription_id,
      external_payment_id: external_payment_id,
      action_source: action
    }

    if event_name == :updated
      case action
      when "subscription.status.changed"
        if previous_changes["status"].present?
          before_status, after_status = previous_changes["status"]
          data[:status_before] = before_status
          data[:status_after] = after_status
        end
      when "subscription.payment.generated"
        if previous_changes["external_payment_id"].present?
          before_payment, after_payment = previous_changes["external_payment_id"]
          data[:external_payment_id_before] = before_payment
          data[:external_payment_id_after] = after_payment
        end
      end
    end

    data
  end

  def sync_company_access
    allows_access? ? company.activate! : company.deactivate!
  end
end
