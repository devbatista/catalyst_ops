source "https://rubygems.org"

ruby "3.3.1"

# Rails
gem "rails", "~> 7.1.5", ">= 7.1.5.1"

# Database
gem "pg", "~> 1.1"

# Web server
gem "puma", ">= 5.0"

# Assets
gem "sprockets-rails"
gem "importmap-rails"

# Hotwire
gem "turbo-rails"
gem "stimulus-rails"

# JSON
gem "jbuilder"

# Boot optimization
gem "bootsnap", require: false

# Timezone data
gem "tzinfo-data", platforms: %i[ windows jruby ]

# === CatalystOps Essentials ===
gem 'devise', '~> 4.9'
gem 'cancancan', '~> 3.5'
gem 'simple_form', '~> 5.3'
gem 'image_processing', '~> 1.2'

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end