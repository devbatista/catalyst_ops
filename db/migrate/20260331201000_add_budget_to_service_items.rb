class AddBudgetToServiceItems < ActiveRecord::Migration[7.1]
  def change
    add_reference :service_items, :budget, null: true, type: :uuid, foreign_key: true
    change_column_null :service_items, :order_service_id, true
  end
end
