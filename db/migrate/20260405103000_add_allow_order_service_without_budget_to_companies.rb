class AddAllowOrderServiceWithoutBudgetToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :allow_order_service_without_budget, :boolean, null: false, default: false
    add_index :companies, :allow_order_service_without_budget, name: "index_companies_on_allow_os_without_budget"
  end
end
