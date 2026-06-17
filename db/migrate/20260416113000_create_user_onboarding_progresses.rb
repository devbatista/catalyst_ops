class CreateUserOnboardingProgresses < ActiveRecord::Migration[7.1]
  def change
    create_table :user_onboarding_progresses, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true, index: { unique: true }
      t.jsonb :completed_steps, null: false, default: {}
      t.string :last_seen_step
      t.datetime :dismissed_at
      t.datetime :finished_at

      t.timestamps
    end

    add_index :user_onboarding_progresses, :finished_at
  end
end
