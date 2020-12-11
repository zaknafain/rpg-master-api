# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'active_model_serializers', require: true
gem 'bcrypt'
gem 'knock'
gem 'pg'
gem 'puma', '~> 5.1.1'
gem 'rack-cors', require: 'rack/cors'
gem 'rails'

gem 'ffaker'

group :development, :test do
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'pry-rails'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  # Rubocop for linting
  gem 'rubocop', '~> 0.92.0', require: false
  gem 'rubocop-rails', '~> 2.9.0', require: false
  gem 'rubocop-rspec', '~> 1.43.1', require: false
end

group :development do
  gem 'listen'
  gem 'spring'
end
