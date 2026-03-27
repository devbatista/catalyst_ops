module Audit
  class Log
    def self.call(action:, resource: nil, metadata: {}, actor: nil, company: nil)
      return if action.blank?

      EventLogger.call(
        action: action,
        source: Current.source || "system",
        actor: actor || Current.user,
        company: company || resolved_company(resource),
        resource: resource,
        metadata: metadata || {},
        request_id: Current.request_id,
        ip_address: Current.ip_address,
        user_agent: Current.user_agent
      )
    rescue StandardError => e
      Rails.logger.error("[Audit::Log] Falha ao registrar #{action}: #{e.message}")
      nil
    end

    def self.resolved_company(resource)
      return Current.user.company if Current.user&.respond_to?(:company) && Current.user.company.present?
      return resource.company if resource&.respond_to?(:company) && resource.company.present?

      nil
    end
  end
end
