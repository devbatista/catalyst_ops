class CreateAuditEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_events, id: :uuid do |t|
      t.datetime :occurred_at, null: false
      t.string :action, null: false
      t.string :source

      t.string :actor_type
      t.string :actor_id

      t.references :company, null: true, type: :uuid, foreign_key: true

      t.string :resource_type
      t.string :resource_id

      t.string :request_id
      t.string :ip_address
      t.text :user_agent

      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :audit_events, :occurred_at
    add_index :audit_events, :action
    add_index :audit_events, :request_id
    add_index :audit_events, [:company_id, :occurred_at], name: "idx_audit_events_company_occurred_at"
    add_index :audit_events, [:actor_type, :actor_id, :occurred_at], name: "idx_audit_events_actor_occurred_at"
    add_index :audit_events, [:resource_type, :resource_id, :occurred_at], name: "idx_audit_events_resource_occurred_at"
  end
end
