class AddIndexesToClients < ActiveRecord::Migration[7.1]
  def change
    add_index :clients, :name
    add_index :clients, :email
    add_index :clients, :phone
    add_index :clients, :document
  end
end
