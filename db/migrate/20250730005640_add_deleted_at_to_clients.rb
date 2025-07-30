class AddDeletedAtToClients < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :deleted_at, :datetime
    add_index :clients, :deleted_at
  end
end
