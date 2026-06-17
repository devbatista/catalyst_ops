return unless ENV["SENTRY_DSN"].present?

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.enabled_environments = %w[production staging]
  config.environment = ENV.fetch("SENTRY_ENVIRONMENT", Rails.env)
  config.release = ENV["SENTRY_RELEASE"].presence

  # Mantemos baixo no início para reduzir custo/ruído.
  config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.1").to_f

  # Evita ruído de erros esperados.
  config.excluded_exceptions += [
    "CanCan::AccessDenied",
    "ActionController::RoutingError"
  ]
end
