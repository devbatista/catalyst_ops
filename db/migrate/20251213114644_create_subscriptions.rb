class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :company, type: :uuid, null: false, foreign_key: true

      t.string :preapproval_plan_id, null: false
      t.string :reason
      t.string :external_reference
      
      t.datetime :start_date
      t.datetime :end_date
      t.datetime :canceled_date
      t.decimal :transaction_amount, precision: 12, scale: 2

      t.string :status, null: false, default: "pending"

      t.string :gateway, default: 'mercado_pago'
      t.string :external_subscription_id
      t.jsonb :raw_payload

      t.timestamps
    end

    add_index :subscriptions, [:company_id, :status]
    add_index :subscriptions, :external_reference
    add_index :subscriptions, :preapproval_plan_id
    add_index :subscriptions, :external_subscription_id
  end
end
