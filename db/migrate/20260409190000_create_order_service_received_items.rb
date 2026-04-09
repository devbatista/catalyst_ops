class CreateOrderServiceReceivedItems < ActiveRecord::Migration[7.1]
  def change
    create_table :order_service_received_items, id: :uuid do |t|
      t.references :order_service, null: false, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.string :brand
      t.string :model
      t.string :serial_number
      t.integer :quantity, null: false, default: 1
      t.text :condition_notes
      t.text :reported_issue
      t.text :accessories

      t.timestamps
    end
  end
end
