class CreatePlans < ActiveRecord::Migration[7.1]
  def change
    create_table :plans, id: :uuid do |t|
      t.string :name, null: false
      t.string :reason, null: false
      t.string :status, null: false, default: "active"

      t.string :external_id, null: false
      t.string :external_reference, null: false

      t.integer :frequency, null: false
      t.string :frequency_type, null: false, default: "months"
      t.decimal :transaction_amount, precision: 10, scale: 2, null: false

      t.string :init_point
      t.string :back_url

      t.timestamps
    end

    add_index :plans, :external_id, unique: true
    add_index :plans, :external_reference, unique: true
    add_index :plans, :status
  end
end
