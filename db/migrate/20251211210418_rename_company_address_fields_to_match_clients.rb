class RenameCompanyAddressFieldsToMatchClients < ActiveRecord::Migration[7.1]
  def change
    rename_column :companies, :street_name,  :street
    rename_column :companies, :street_number, :number
    rename_column :companies, :federal_unit, :state
  end
end