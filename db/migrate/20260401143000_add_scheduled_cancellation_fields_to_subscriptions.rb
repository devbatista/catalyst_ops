class AddScheduledCancellationFieldsToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :cancel_at_period_end, :boolean, null: false, default: false
    add_column :subscriptions, :cancel_requested_at, :datetime
    add_column :subscriptions, :cancel_effective_on, :date
    add_column :subscriptions, :cancel_reason, :string

    add_index :subscriptions, :cancel_at_period_end
    add_index :subscriptions, :cancel_effective_on
  end
end
