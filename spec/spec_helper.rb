# frozen_string_literal: true
# This file is copied to spec/ when you run 'rails generate rspec:install'
# Has been customized by Blacklight to work when application is in one place,
# and actual spec/ stuff is in another (the blacklight gem checkout).  

ENV["RAILS_ENV"] ||= 'test'

if ENV["COVERAGE"] or ENV["CI"]
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter "/spec/"
  end
end

require 'rsolr'
require 'blacklight'

require 'engine_cart'
EngineCart.load_application!

require 'rspec/rails'
require 'rspec/its'
require 'rspec/collection_matchers'
require 'capybara/rspec'
require 'capybara/poltergeist'


Capybara.javascript_driver = :poltergeist

Capybara.register_driver :poltergeist do |app|
  options = {}

  options[:timeout] = 120 if RUBY_PLATFORM == "java"

  Capybara::Poltergeist::Driver.new(app, options)
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
# Blacklight, again, make sure we're looking in the right place for em. 
# Relative to HERE, NOT to Rails.root, which is off somewhere else. 
Dir[Pathname.new(File.expand_path("../support/**/*.rb", __FILE__))].each {|f| require f}

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.include Devise::TestHelpers, type: :controller
  config.infer_spec_type_from_file_location!

  config.include(ControllerLevelHelpers, type: :helper)
  config.before(:each, type: :helper) { initialize_controller_helpers(helper) }

  config.include(ControllerLevelHelpers, type: :view)
  config.before(:each, type: :view) { initialize_controller_helpers(view) }
end
