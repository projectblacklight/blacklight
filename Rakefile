# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

BlacklightApp::Application.load_tasks

begin 
  require "jeweler"
  Jeweler::Tasks.new do |gem|
    gem.name = "blacklight"
    gem.summary = "Blacklight Engine for Rails 3"
    gem.files = Dir["{lib}/**/*", "{app}/**/*", "{config}/**/*"]
    # other fields that would normally go in your gemspec
    # like authors, email and has_rdoc can also be included here
  end
rescue
  puts "Jeweler or one of its dependencies is not installed."
end
