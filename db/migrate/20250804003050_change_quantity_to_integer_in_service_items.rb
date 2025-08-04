class ChangeQuantityToIntegerInServiceItems < ActiveRecord::Migration[7.1]
  def up
    change_column :service_items, :quantity, :integer, using: 'quantity::integer'
  end

  def down
    change_column :service_items, :quantity, :decimal
  end
end