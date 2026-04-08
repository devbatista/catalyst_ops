class AddAllowSimultaneousOrderServicesToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :allow_simultaneous_order_services, :boolean, null: false, default: false
    add_index :companies, :allow_simultaneous_order_services, name: "index_companies_on_allow_simultaneous_os"
  end
end
