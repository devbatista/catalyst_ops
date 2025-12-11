class AddPlanAndPaymentMethodToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_reference :companies, :plan, type: :uuid, null: true, foreign_key: true
    add_column :companies, :payment_method, :string, null: false, default: "boleto"

    add_index :companies, :payment_method
  end
end
