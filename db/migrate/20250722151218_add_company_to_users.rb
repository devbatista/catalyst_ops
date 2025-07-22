class AddCompanyToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :company, type: :uuid, foreign_key: true, null: true
  end
end
