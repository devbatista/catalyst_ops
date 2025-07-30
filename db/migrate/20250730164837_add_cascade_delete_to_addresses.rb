class AddCascadeDeleteToAddresses < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :addresses, :clients
    add_foreign_key :addresses, :clients, on_delete: :cascade
  end
end