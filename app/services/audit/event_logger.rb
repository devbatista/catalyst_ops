module Audit
  class EventLogger
    def self.call(**args)
      new(**args).call
    end

    def initialize(action:, source: nil, actor: nil, company: nil, resource: nil, metadata: {}, request_id: nil, ip_address: nil, user_agent: nil, occurred_at: Time.current)
      @action = action.to_s
      @source = source.presence&.to_s
      @actor = actor
      @company = company
      @resource = resource
      @metadata = metadata.presence || {}
      @request_id = request_id
      @ip_address = ip_address
      @user_agent = user_agent
      @occurred_at = occurred_at
    end

    def call
      AuditEvent.create!(
        action: @action,
        source: @source,
        actor_type: actor_type,
        actor_id: actor_id,
        company: resolved_company,
        resource_type: resource_type,
        resource_id: resource_id,
        request_id: @request_id,
        ip_address: @ip_address,
        user_agent: @user_agent,
        metadata: normalized_metadata,
        occurred_at: @occurred_at
      )
    end

    private

    def actor_type
      @actor&.class&.name
    end

    def actor_id
      @actor&.id&.to_s
    end

    def resource_type
      @resource&.class&.name
    end

    def resource_id
      @resource&.id&.to_s
    end

    def resolved_company
      return @company if @company.present?
      return @actor.company if @actor.respond_to?(:company) && @actor.company.present?
      return @resource.company if @resource.respond_to?(:company) && @resource.company.present?

      nil
    end

    def normalized_metadata
      @metadata.is_a?(Hash) ? @metadata : { value: @metadata.to_s }
    end
  end
end
