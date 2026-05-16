class AddDocumentTypeToCompanyPdfSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :company_pdf_settings, :document_type, :string, null: false, default: "order_service"

    remove_index :company_pdf_settings, :company_id
    add_index :company_pdf_settings, [:company_id, :document_type], unique: true
  end
end
