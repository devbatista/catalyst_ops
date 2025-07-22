class AddCompanyToClients < ActiveRecord::Migration[7.1]
  def change
    add_reference :clients, :company, type: :uuid, foreign_key: true, null: false
  end
end
