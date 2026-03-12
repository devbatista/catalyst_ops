class CreateSupportTicket < ActiveRecord::Migration[7.1]
  def change
    create_table :support_tickets, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :order_service, null: true, foreign_key: true, type: :uuid

      t.string :subject, null: false
      t.text :description, null: false

      t.integer :category, null: false, default: 0
      t.integer :impact, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.integer :priority, null: false, default: 1

      t.references :assigned_to, null: true, foreign_key: { to_table: :users }, type: :uuid

      t.datetime :last_reply_at

      t.timestamps
    end

    add_index :support_tickets, [:company_id, :status]
    add_index :support_tickets, [:company_id, :priority]
    add_index :support_tickets, [:company_id, :created_at]
  end
end
