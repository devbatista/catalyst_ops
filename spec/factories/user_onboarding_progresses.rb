FactoryBot.define do
  factory :user_onboarding_progress do
    user
    completed_steps { {} }
    last_seen_step { nil }
    dismissed_at { nil }
    finished_at { nil }
  end
end
