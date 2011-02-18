# Load the rails application
require File.expand_path('../application', __FILE__)


if RUBY_PLATFORM =~ /java/
  require 'arjdbc' 
#   require 'rubygems'
#   gem 'activerecord-jdbc-adapter'
#   require 'arjdbc'
 end


# Initialize the rails application
BlacklightApp::Application.initialize!

# NOTE:  With the move to rails 3, the configuration
# settings you explect to find here are moved to 
# config/application.rb - Gems (installed through bundler)
# are actually now specified in the blacklight.gemspec file

