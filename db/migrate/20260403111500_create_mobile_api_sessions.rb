class CreateMobileApiSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :mobile_api_sessions, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :last_used_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :mobile_api_sessions, :token_digest, unique: true
    add_index :mobile_api_sessions, [:user_id, :revoked_at]
    add_index :mobile_api_sessions, :expires_at
  end
end
