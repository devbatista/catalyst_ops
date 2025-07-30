class AddIndexesToUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :name
    add_index :users, [:name, :email]
  end
end
