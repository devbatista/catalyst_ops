class ChangeActiveStorageRecordIdToUuid < ActiveRecord::Migration[7.1]
  def up
    execute("DELETE FROM active_storage_attachments;")
    change_column :active_storage_attachments, :record_id, :uuid, using: 'record_id::text::uuid'
  end

  def down
    change_column :active_storage_attachments, :record_id, :bigint
  end
end