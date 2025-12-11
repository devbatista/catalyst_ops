class AddAddressFieldsToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :zip_code, :string
    add_column :companies, :street_name, :string
    add_column :companies, :street_number, :string
    add_column :companies, :complement, :string, null: true
    add_column :companies, :neighborhood, :string
    add_column :companies, :city, :string
    add_column :companies, :federal_unit, :string

    add_index :companies, :zip_code
    add_index :companies, %i[city federal_unit]
  end
end
