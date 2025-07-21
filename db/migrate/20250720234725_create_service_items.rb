class CreateServiceItems < ActiveRecord::Migration[7.1]
  def change
    create_table :service_items, id: :uuid do |t|
      t.text :description
      t.decimal :quantity
      t.decimal :unit_price
      t.references :order_service, null: false, type: :uuid, foreign_key: true

      t.timestamps
    end
  end
end
