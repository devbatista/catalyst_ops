class CreateReports < ActiveRecord::Migration[7.1]
  def change
    create_table :reports, id: :uuid do |t|
      t.string :title, null: false
      t.string :report_type, null: false
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.datetime :generated_at
      t.string :status, default: "pending"
      t.text :filters
      t.string :file
      t.text :error_message

      t.timestamps
    end

    add_index :reports, [:company_id, :report_type]
    add_index :reports, [:company_id, :status]
    add_index :reports, [:company_id, :generated_at]
  end
end
