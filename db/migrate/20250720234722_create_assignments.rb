class CreateAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :assignments, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.references :order_service, null: false, type: :uuid, foreign_key: true

      t.timestamps
    end
  end
end
