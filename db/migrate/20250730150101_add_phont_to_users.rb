class AddPhontToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :phone, :string
    add_index :users, :phone
  end
end
