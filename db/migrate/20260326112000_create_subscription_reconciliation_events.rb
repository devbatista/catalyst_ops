class CreateSubscriptionReconciliationEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :subscription_reconciliation_events, id: :uuid do |t|
      t.references :subscription, null: false, type: :uuid, foreign_key: true
      t.references :company, null: false, type: :uuid, foreign_key: true
      t.string :source_job, null: false
      t.integer :window_days
      t.string :payment_method, null: false
      t.string :gateway_identifier, null: false
      t.string :gateway_status
      t.string :local_status_before
      t.string :local_status_after
      t.boolean :divergent, null: false, default: false
      t.boolean :resolved, null: false, default: false
      t.string :result_status, null: false, default: "success"
      t.text :error_message
      t.jsonb :raw_payload, null: false, default: {}
      t.datetime :processed_at, null: false

      t.timestamps
    end

    add_index :subscription_reconciliation_events, :processed_at
    add_index :subscription_reconciliation_events, [:source_job, :processed_at], name: "idx_reconciliation_events_source_processed_at"
    add_index :subscription_reconciliation_events, [:divergent, :resolved], name: "idx_reconciliation_events_divergent_resolved"
    add_index :subscription_reconciliation_events, :result_status
  end
end
