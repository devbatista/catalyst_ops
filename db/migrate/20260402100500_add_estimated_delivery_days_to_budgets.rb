class AddEstimatedDeliveryDaysToBudgets < ActiveRecord::Migration[7.1]
  def change
    add_column :budgets, :estimated_delivery_days, :integer
  end
end
