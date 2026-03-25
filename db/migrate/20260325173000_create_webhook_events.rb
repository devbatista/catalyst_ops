class CreateWebhookEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :webhook_events, id: :uuid do |t|
      t.string :provider, null: false
      t.string :event_key, null: false
      t.string :resource_id
      t.string :event_type
      t.string :status, null: false, default: "received"
      t.datetime :processed_at
      t.text :error_message
      t.jsonb :payload, null: false, default: {}

      t.timestamps
    end

    add_index :webhook_events, [:provider, :event_key], unique: true
    add_index :webhook_events, [:provider, :resource_id]
    add_index :webhook_events, :status
  end
end
