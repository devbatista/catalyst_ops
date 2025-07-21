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

# Validação de CPF/CNPJ
gem 'cpf_cnpj', '~> 0.5.0'

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]

  gem 'rspec-rails', '~>6.1'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'faker', '~> 3.2'

  gem 'pry-byebug'
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"

  gem 'shoulda-matchers', '~> 5.3'
end