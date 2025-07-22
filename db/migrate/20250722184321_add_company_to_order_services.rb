class AddCompanyToOrderServices < ActiveRecord::Migration[7.1]
  def change
    add_reference :order_services, :company, type: :uuid, foreign_key: true, null: false
  end
end
