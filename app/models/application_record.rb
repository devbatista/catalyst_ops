class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  after_initialize :ensure_uuid_for_primary_key

  private

  def ensure_uuid_for_primary_key
    if self.class.primary_key == "id" && self.id.blank? && self.class.columns_hash["id"]&.type == :uuid
      self.id = SecureRandom.uuid
    end
  end
end