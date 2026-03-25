class AddExternalPaymentIdToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :external_payment_id, :string
    add_index :subscriptions, :external_payment_id
  end
end
