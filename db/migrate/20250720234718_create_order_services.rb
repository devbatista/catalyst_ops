class CreateOrderServices < ActiveRecord::Migration[7.1]
  def change
    create_table :order_services, id: :uuid do |t|
      t.string :title
      t.text :description
      t.references :client, null: false, type: :uuid, foreign_key: true
      t.integer :status
      t.datetime :scheduled_at
      t.datetime :started_at
      t.datetime :finished_at
      t.boolean :signed_by_client

      t.timestamps
    end
  end
end
