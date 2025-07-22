class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies, id: :uuid do |t|
      t.string :name, null: false
      t.string :document, null: false #CPF ou CNPJ
      t.string :email, null: false
      t.string :phone, null: false
      t.references :responsible, type: :uuid, foreign_key: { to_table: :users }, null: true
      
      #campos opcionais
      t.text :address
      t.string :state_registration
      t.string :municipal_registration
      t.string :website

      t.timestamps
    end

    add_index :companies, :document, unique: true
    add_index :companies, :email, unique: true
  end
end
