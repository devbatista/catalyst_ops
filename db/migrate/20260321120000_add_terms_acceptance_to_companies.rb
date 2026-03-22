class AddTermsAcceptanceToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :terms_version_accepted, :string
    add_column :companies, :terms_accepted_at, :datetime
    add_column :companies, :terms_accepted_ip, :string
    add_column :companies, :terms_accepted_user_agent, :text
    add_reference :companies, :terms_accepted_by_user, type: :uuid, foreign_key: { to_table: :users }

    add_index :companies, :terms_version_accepted
  end
end
