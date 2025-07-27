class RemoveAddressFromClients < ActiveRecord::Migration[7.1]
  def change
    remove_column :clients, :address, :string
  end
end
