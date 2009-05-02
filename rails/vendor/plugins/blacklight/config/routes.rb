# Rails Engines plugin has the routes file at the plugin root rather than in config.
# We need to pretend it's in config for running Blacklight as a stand-alone app.
require File.join(File.dirname(__FILE__), '../routes.rb')