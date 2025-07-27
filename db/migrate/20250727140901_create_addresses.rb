class CreateAddresses < ActiveRecord::Migration[7.1]
  def change
    create_table :addresses, id: :uuid do |t|
      t.references :client, type: :uuid, null: false, foreign_key: true
      t.string :street
      t.string :number
      t.string :complement
      t.string :neighborhood
      t.string :zip_code
      t.string :city
      t.string :state
      t.string :country
      t.string :address_type
      t.timestamps
    end
  end
end
