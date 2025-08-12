
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins /.*\.catalystops\.local/
    resource '*',
      headers: :any,
      methods: [:get, :post, :delete, :put, :patch, :options, :head],
      credentials: true
  end
end