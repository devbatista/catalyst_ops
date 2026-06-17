class AddMaxBudgetsToPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :plans, :max_budgets, :integer
  end
end
