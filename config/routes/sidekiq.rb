require 'sidekiq/web'
mount Sidekiq::Web => '/', constraints: ->(req) { req.host == 'sidekiq.catalystops.local' }