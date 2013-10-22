# encoding: UTF-8
require 'rubygems'
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

# load rake tasks defined in lib/tasks that are not loaded in lib/active_fedora.rb
load "tasks/blacklight.rake"

task :default => [:ci]
task :clean => ['blacklight:clean']

