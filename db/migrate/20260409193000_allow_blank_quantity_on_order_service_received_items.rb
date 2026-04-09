class AllowBlankQuantityOnOrderServiceReceivedItems < ActiveRecord::Migration[7.1]
  def change
    change_column_default :order_service_received_items, :quantity, from: 1, to: nil
    change_column_null :order_service_received_items, :quantity, true
  end
end
