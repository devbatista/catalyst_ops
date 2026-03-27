Rails.application.config.to_prepare do
  next unless defined?(ActiveStorage::Attachment)

  next if ActiveStorage::Attachment.method_defined?(:audit_order_service_attachment_added)

  ActiveStorage::Attachment.class_eval do
    after_create_commit :audit_order_service_attachment_added
    after_destroy_commit :audit_order_service_attachment_removed

    private

    def audit_order_service_attachment_added
      order_service = auditable_order_service_resource
      return if order_service.blank?

      Audit::Log.call(
        action: "order_service.attachment.added",
        resource: order_service,
        metadata: attachment_metadata(event: "added", order_service: order_service)
      )
    end

    def audit_order_service_attachment_removed
      order_service = auditable_order_service_resource
      return if order_service.blank?

      Audit::Log.call(
        action: "order_service.attachment.removed",
        resource: order_service,
        metadata: attachment_metadata(event: "removed", order_service: order_service)
      )
    end

    def auditable_order_service_resource
      return unless name == "attachments"
      return unless record_type == "OrderService"

      if record.is_a?(OrderService)
        record
      else
        OrderService.find_by(id: record_id)
      end
    end

    def attachment_metadata(event:, order_service:)
      {
        event: event,
        attachment_id: id,
        filename: blob&.filename&.to_s,
        byte_size: blob&.byte_size,
        content_type: blob&.content_type,
        record_type: record_type,
        record_id: record_id,
        order_service_id: order_service.id,
        order_service_code: order_service.code,
        status: order_service.status,
        company_id: order_service.company_id
      }
    end
  end
end
