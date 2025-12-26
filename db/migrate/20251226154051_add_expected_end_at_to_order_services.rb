class AddExpectedEndAtToOrderServices < ActiveRecord::Migration[7.1]
  def change
    add_column :order_services, :expected_end_at, :datetime
  end
end
