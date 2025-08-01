class ChangeDefaultActiveOnUsers < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :active, from: true, to: false
  end
end
