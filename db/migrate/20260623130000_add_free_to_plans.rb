class AddFreeToPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :plans, :free, :boolean, default: false, null: false
    add_index :plans, :free
  end
end
