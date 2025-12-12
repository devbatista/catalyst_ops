class AddActiveToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :active, :boolean, null: false, default: false
    
    add_index :companies, :active
  end
end
