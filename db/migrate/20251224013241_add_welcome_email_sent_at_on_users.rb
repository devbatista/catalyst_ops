class AddWelcomeEmailSentAtOnUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :welcome_email_sent_at, :datetime
  end
end
