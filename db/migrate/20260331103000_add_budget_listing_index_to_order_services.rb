class AddBudgetListingIndexToOrderServices < ActiveRecord::Migration[7.1]
  def change
    add_index :order_services,
              [:company_id, :status, :created_at],
              name: "index_order_services_on_company_status_created_at"
  end
end
