# frozen_string_literal: true

require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../config/environment', __dir__)

abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'database_cleaner'

# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

RSpec::Matchers.define :of_correct_schema? do |name, owned_id, as_admin|
  match do |actual|
    parsed_response = JSON.parse(actual)
    parsed_response = [parsed_response].flatten

    validations = parsed_response.map do |single|
      schema = load_schema_file(single, name, owned_id, as_admin)

      collect_schema_validations(single, schema)
    end

    validations.flatten.all? { |v| v == true }
  end

  failure_message { |a| "expected that #{a} would be of schema #{name}" }

  def load_schema_file(parsed_item, schema_name, owned_id, as_admin)
    if as_admin
      schema_name = "#{schema_name}_admin"
    elsif owned_id == parsed_item['id']
      schema_name = "#{schema_name}_owner"
    end

    File.read("spec/fixtures/schemas/#{schema_name}.json")
  end

  def collect_schema_validations(parsed_response, schema)
    expected_schema = JSON.parse(schema)['properties']
    keys = (expected_schema.keys + parsed_response.keys).uniq

    keys.map do |key|
      types = expected_schema.dig(key, 'types') ||
              [expected_schema.dig(key, 'type')]

      types.any? { |t| t == parsed_response[key].class.to_s }
    end
  end
end

def auth_header(user)
  token = auth_token(user)

  { 'Authorization' => "Bearer #{token}" }
end

def auth_token(user)
  payload = user.to_token_payload

  JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
end

def decoded_token(token)
  JWT.decode(token, Rails.application.secrets.secret_key_base, true, algorithm: 'HS256')
end
