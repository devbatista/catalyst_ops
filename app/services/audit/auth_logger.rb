module Audit
  class AuthLogger
    def self.login_succeeded(user:)
      Audit::Log.call(
        action: "auth.login.succeeded",
        actor: user,
        company: user&.company,
        metadata: {
          user_id: user&.id,
          role: user&.role,
          email: user&.email
        }
      )
    end

    def self.login_failed(email:, user:)
      failure_reason =
        if user.blank?
          "user_not_found"
        elsif !user.active?
          "inactive_user"
        else
          "invalid_password"
        end

      Audit::Log.call(
        action: "auth.login.failed",
        actor: user,
        company: user&.company,
        metadata: {
          email: email,
          reason: failure_reason
        }
      )
    end

    def self.logout_succeeded(user:)
      Audit::Log.call(
        action: "auth.logout.succeeded",
        actor: user,
        company: user&.company,
        metadata: {
          user_id: user&.id,
          email: user&.email
        }
      )
    end
  end
end
