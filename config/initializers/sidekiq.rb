require "sidekiq"
require "sidekiq/cron/job"

REDIS_URL = ENV.fetch("REDIS_URL") { "redis://redis:6379/0" }

Sidekiq.configure_server do |config|
  config.redis = {
    url: REDIS_URL,
    network_timeout: 5,
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: REDIS_URL,
    network_timeout: 5,
  }
end