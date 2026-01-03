class AddExpiredDateToSubscription < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :expired_date, :date
  end
end
