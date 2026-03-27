module Auditable
  extend ActiveSupport::Concern

  included do
    after_create_commit :audit_created_event
    after_update_commit :audit_updated_events
    after_destroy_commit :audit_deleted_event
  end

  private

  def audit_created_event
    action = auditable_created_action
    return if action.blank? || !Audit::ActionCatalog.include?(action)

    Audit::Log.call(
      action: action,
      resource: self,
      metadata: auditable_metadata(:created, action: action)
    )
  end

  def audit_updated_events
    return if previous_changes.except("updated_at").blank?

    actions = Array(auditable_updated_actions).compact.uniq
    actions.each do |action|
      next unless Audit::ActionCatalog.include?(action)

      Audit::Log.call(
        action: action,
        resource: self,
        metadata: auditable_metadata(:updated, action: action)
      )
    end
  end

  def audit_deleted_event
    action = auditable_deleted_action
    return if action.blank? || !Audit::ActionCatalog.include?(action)

    Audit::Log.call(
      action: action,
      resource: self,
      metadata: auditable_metadata(:deleted, action: action)
    )
  end

  def auditable_created_action
    "#{self.class.name.underscore}.created"
  end

  def auditable_updated_actions
    [ "#{self.class.name.underscore}.updated" ]
  end

  def auditable_deleted_action
    "#{self.class.name.underscore}.deleted"
  end

  def auditable_metadata(event_name, action:)
    data = {
      event: event_name.to_s,
      model: self.class.name,
      record_id: id,
      action_source: action
    }

    if event_name == :updated
      changes = previous_changes.except("updated_at")
      data[:changes] = changes if changes.present?
    end

    data
  end
end
