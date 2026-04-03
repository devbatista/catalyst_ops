class AddDiscountFieldsToOrderServices < ActiveRecord::Migration[7.1]
  def change
    add_column :order_services, :discount_type, :string, null: false, default: "none"
    add_column :order_services, :discount_value, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_column :order_services, :discount_reason, :text
  end
end
