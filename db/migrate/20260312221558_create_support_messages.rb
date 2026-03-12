class CreateSupportMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :support_messages, id: :uuid do |t|
      t.references :support_ticket, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.text :body, null: false
      t.boolean :internal, null: false, default: false

      t.timestamps
    end
    
    add_index :support_messages, [:support_ticket_id, :created_at]
  end
end
