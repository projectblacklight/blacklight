# encoding: UTF-8
require 'rubygems'
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rake'
Bundler::GemHelper.install_tasks

# load rake tasks defined in lib/tasks that are not loaded in lib/active_fedora.rb
load "tasks/blacklight.rake"

task :default => [:ci]
task :spec => ['blacklight:spec']
task :clean => ['blacklight:clean']

