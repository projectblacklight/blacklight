# encoding: UTF-8
require 'rubygems'
require 'rails'
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

load "tasks/blacklight.rake"
load "lib/railties/blacklight.rake"

task :default => [:rubocop, :ci]
