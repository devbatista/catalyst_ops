class App::OnboardingProgressController < ApplicationController
  skip_authorization_check

  ALLOWED_OPERATIONS = %w[complete_step dismiss resume finish].freeze

  def show
    render json: response_payload
  end

  def update
    operation = params[:operation].to_s

    return render_invalid_operation if operation.blank? || !ALLOWED_OPERATIONS.include?(operation)

    case operation
    when "complete_step"
      return render_missing_step_key if params[:step_key].blank?

      onboarding_progress.complete_step!(params[:step_key])
    when "dismiss"
      onboarding_progress.dismiss!
    when "resume"
      onboarding_progress.resume!
    when "finish"
      onboarding_progress.finish!
    end

    render json: response_payload
  rescue ArgumentError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  private

  def onboarding_progress
    @onboarding_progress ||= UserOnboardingProgress.find_or_create_by!(user: current_user)
  end

  def response_payload
    {
      success: true,
      onboarding_progress: {
        completed_steps: onboarding_progress.completed_steps,
        completed_steps_count: onboarding_progress.completed_steps_count,
        steps_total: UserOnboardingProgress::STEP_KEYS.size,
        progress_percentage: onboarding_progress.progress_percentage,
        last_seen_step: onboarding_progress.last_seen_step,
        dismissed: onboarding_progress.dismissed_at.present?,
        dismissed_at: onboarding_progress.dismissed_at,
        finished: onboarding_progress.finished_at.present?,
        finished_at: onboarding_progress.finished_at,
        step_keys: UserOnboardingProgress::STEP_KEYS
      }
    }
  end

  def render_invalid_operation
    render json: {
      success: false,
      error: "Invalid operation. Allowed operations: #{ALLOWED_OPERATIONS.join(', ')}"
    }, status: :unprocessable_entity
  end

  def render_missing_step_key
    render json: { success: false, error: "step_key is required for operation complete_step" }, status: :unprocessable_entity
  end
end
