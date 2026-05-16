class CreateCompanyPdfSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :company_pdf_settings, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.string :accent_color, null: false, default: "1F6FEB"
      t.string :header_subtitle
      t.string :document_note
      t.string :footer_text
      t.boolean :show_company_data, null: false, default: true
      t.boolean :show_client_data, null: false, default: true
      t.boolean :show_service_description, null: false, default: true
      t.boolean :show_service_items, null: false, default: true
      t.boolean :show_observations, null: false, default: true
      t.boolean :show_discount_reason, null: false, default: true

      t.timestamps
    end
  end
end
