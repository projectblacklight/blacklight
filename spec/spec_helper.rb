# -*- encoding : utf-8 -*-
# This file is copied to spec/ when you run 'rails generate rspec:install'
# Has been customized by Blacklight to work when application is in one place,
# and actual spec/ stuff is in another (the blacklight gem checkout).  

ENV["RAILS_ENV"] ||= 'test'

ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
if ENV['COVERAGE'] and ruby_engine != "jruby"
  require 'simplecov'

  SimpleCov.start do
    root File.expand_path(File.dirname(__FILE__) + "../../..")
  end
end

require 'blacklight'
require 'blacklight_marc'

require 'engine_cart'
EngineCart.load_application!

require 'rspec/rails'
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
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
end
