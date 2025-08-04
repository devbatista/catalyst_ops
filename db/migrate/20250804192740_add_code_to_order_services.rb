class AddCodeToOrderServices < ActiveRecord::Migration[7.1]
  def change
    add_column :order_services, :code, :integer
    add_index :order_services, [:company_id, :code], unique: true
  end
end
