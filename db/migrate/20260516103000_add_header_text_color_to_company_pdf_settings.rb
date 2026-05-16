class AddHeaderTextColorToCompanyPdfSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :company_pdf_settings, :header_text_color, :string
  end
end
