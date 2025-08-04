class AddObservationsToOrderServices < ActiveRecord::Migration[7.1]
  def change
    add_column :order_services, :observations, :text
  end
end
