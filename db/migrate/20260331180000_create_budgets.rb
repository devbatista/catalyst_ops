class CreateBudgets < ActiveRecord::Migration[7.1]
  def change
    create_table :budgets, id: :uuid do |t|
      t.references :company, null: false, type: :uuid, foreign_key: true
      t.references :client, null: false, type: :uuid, foreign_key: true
      t.references :order_service, null: true, type: :uuid, foreign_key: true

      t.integer :code, null: false
      t.string :title, null: false
      t.text :description
      t.integer :status, null: false, default: 0

      t.decimal :total_value, precision: 12, scale: 2, null: false, default: 0
      t.date :valid_until

      t.datetime :approval_sent_at
      t.datetime :approved_at
      t.datetime :rejected_at
      t.text :rejection_reason

      t.timestamps
    end

    add_index :budgets, [:company_id, :code], unique: true
    add_index :budgets, [:company_id, :status]
    add_index :budgets, :created_at
  end
end
