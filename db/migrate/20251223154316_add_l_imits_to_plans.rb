class AddLImitsToPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :plans, :max_technicians, :integer
    add_column :plans, :max_orders, :integer
    add_column :plans, :support_level, :string
  end
end