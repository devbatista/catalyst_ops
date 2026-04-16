class UserOnboardingProgress < ApplicationRecord
  STEP_KEYS = %w[
    created_technician
    created_customer
    created_first_work_order
    moved_work_order_status
    viewed_reports
  ].freeze

  belongs_to :user

  validates :user_id, presence: true, uniqueness: true
  validates :last_seen_step, inclusion: { in: STEP_KEYS }, allow_nil: true

  before_validation :normalize_completed_steps!

  def complete_step!(step_key)
    key = normalize_step_key(step_key)

    steps = (completed_steps || {}).dup
    step_already_completed = steps[key] == true
    steps[key] = true

    self.completed_steps = steps
    self.last_seen_step = key
    self.finished_at = Time.current if finished_all_steps?

    save! if changed?

    !step_already_completed
  end

  def completed_step?(step_key)
    key = normalize_step_key(step_key)
    completed_steps.fetch(key, false) == true
  end

  def completed_steps_count
    completed_step_keys.count
  end

  def progress_percentage
    return 0 if STEP_KEYS.empty?

    ((completed_steps_count.to_f / STEP_KEYS.size) * 100).round
  end

  def dismiss!
    update!(dismissed_at: Time.current)
  end

  def resume!
    update!(dismissed_at: nil)
  end

  def finish!
    update!(finished_at: Time.current)
  end

  def finished_all_steps?
    (STEP_KEYS - completed_step_keys).empty?
  end

  private

  def completed_step_keys
    completed_steps
      .select { |step, done| STEP_KEYS.include?(step) && done == true }
      .keys
  end

  def normalize_completed_steps!
    self.completed_steps = (completed_steps || {})
      .to_h
      .transform_keys(&:to_s)
      .slice(*STEP_KEYS)
      .transform_values { |value| value == true }
  end

  def normalize_step_key(step_key)
    key = step_key.to_s
    return key if STEP_KEYS.include?(key)

    raise ArgumentError, "Invalid onboarding step: #{step_key}"
  end
end
