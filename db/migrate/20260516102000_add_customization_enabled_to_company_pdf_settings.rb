class AddCustomizationEnabledToCompanyPdfSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :company_pdf_settings, :customization_enabled, :boolean, null: false, default: false
  end
end
