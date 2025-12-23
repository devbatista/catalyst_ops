require 'sidekiq/web'
require 'sidekiq/cron/web'

mount Sidekiq::Web => '/', constraints: ->(req) { req.host == 'sidekiq.catalystops.local' }