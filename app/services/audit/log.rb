module Audit
  class Log
    SCHEMA_VERSION = 1

    def self.call(action:, resource: nil, metadata: {}, actor: nil, company: nil)
      return if action.blank?

      source = Current.source || "system"
      resolved_actor = actor || Current.user
      resolved_company_record = company || resolved_company(resource)
      normalized_metadata = normalize_metadata(metadata)

      EventLogger.call(
        action: action,
        source: source,
        actor: resolved_actor,
        company: resolved_company_record,
        resource: resource,
        metadata: standardized_metadata(
          action: action,
          source: source,
          actor: resolved_actor,
          company: resolved_company_record,
          resource: resource,
          metadata: normalized_metadata
        ),
        request_id: Current.request_id,
        ip_address: Current.ip_address,
        user_agent: Current.user_agent
      )
    rescue StandardError => e
      Rails.logger.error("[Audit::Log] Falha ao registrar #{action}: #{e.message}")
      nil
    end

    def self.standardized_metadata(action:, source:, actor:, company:, resource:, metadata:)
      payload = metadata.deep_stringify_keys

      payload["schema_version"] ||= SCHEMA_VERSION
      payload["event"] ||= action.to_s.split(".").last
      payload["action"] ||= action.to_s
      payload["source"] ||= source
      payload["request_id"] ||= Current.request_id
      payload["ip_address"] ||= Current.ip_address
      payload["user_agent"] ||= Current.user_agent
      payload["actor"] ||= compact_hash(type: actor&.class&.name, id: actor&.id&.to_s)
      payload["company"] ||= compact_hash(id: company&.id&.to_s, name: company&.respond_to?(:name) ? company.name : nil)
      payload["resource"] ||= compact_hash(type: resource&.class&.name, id: resource&.id&.to_s)
      payload["details"] ||= details_payload(payload)

      compact_hash(payload)
    end

    def self.details_payload(payload)
      payload.except(
        "schema_version",
        "event",
        "action",
        "source",
        "request_id",
        "ip_address",
        "user_agent",
        "actor",
        "company",
        "resource",
        "details"
      )
    end

    def self.normalize_metadata(metadata)
      return {} if metadata.blank?
      return metadata if metadata.is_a?(Hash)

      { value: metadata.to_s }
    end

    def self.compact_hash(hash)
      hash.each_with_object({}) do |(key, value), memo|
        next if value.nil?

        memo[key] =
          if value.is_a?(Hash)
            nested = compact_hash(value)
            next if nested.empty?

            nested
          else
            value
          end
      end
    end

    def self.resolved_company(resource)
      return Current.user.company if Current.user&.respond_to?(:company) && Current.user.company.present?
      return resource.company if resource&.respond_to?(:company) && resource.company.present?

      nil
    end
  end
end
