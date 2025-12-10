class AddPlanAndPaymentMethodToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_reference :companies, :plan, foreign_key: true, null: false
    add_column :companies, :payment_method, :string, null: false, default: "boleto"

    add_index :companies, :payment_method
  end
end
