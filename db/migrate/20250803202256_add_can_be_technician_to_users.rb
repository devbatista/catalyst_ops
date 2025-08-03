class AddCanBeTechnicianToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :can_be_technician, :boolean, default: false
  end
end
