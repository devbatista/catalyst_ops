class AddExpirationWarningSentAtToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :expiration_warning_sent_at, :datetime
    add_index :subscriptions, :expiration_warning_sent_at
  end
end
