class RemoveAddressFromCompanies < ActiveRecord::Migration[7.1]
  def change
    remove_column :companies, :address, :string
  end
end
