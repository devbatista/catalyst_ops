class AddExpiredNotificationSentAtToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :expired_notification_sent_at, :datetime
    add_index :subscriptions, :expired_notification_sent_at
  end
end
