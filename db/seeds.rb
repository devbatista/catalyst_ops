Dir[Rails.root.join('db/seeds/common/*.rb')].sort.each { |file| load file }

env_dir = Rails.root.join('db', 'seeds', Rails.env)
if Dir.exist?(env_dir)
  Dir[env_dir.join('*.rb')].sort.each { |file| load file }
end