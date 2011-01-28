# Load the rails application
require File.expand_path('../application', __FILE__)
require 'arjdbc' 

# Initialize the rails application
BlacklightApp::Application.initialize!

# NOTE:  With the move to rails 3, the configuration
# settings you explect to find here are moved to 
# config/application.rb

