module OnboardingTracking
  private

  def mark_onboarding_step(step_key)
    return unless current_user

    progress = current_user.user_onboarding_progress || current_user.create_user_onboarding_progress!
    progress.complete_step!(step_key)
  rescue StandardError => e
    Rails.logger.warn("[OnboardingTracking] Failed to complete step '#{step_key}' for user #{current_user&.id}: #{e.class} - #{e.message}")
  end
end
