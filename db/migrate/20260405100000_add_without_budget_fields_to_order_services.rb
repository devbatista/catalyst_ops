class AddWithoutBudgetFieldsToOrderServices < ActiveRecord::Migration[7.1]
  def change
    add_column :order_services, :created_without_budget, :boolean, null: false, default: false
    add_column :order_services, :budget_waiver_reason, :text
    add_column :order_services, :budget_waiver_authorized_by, :string

    add_index :order_services, :created_without_budget
  end
end
