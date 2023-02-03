# frozen_string_literal: true

require 'rubygems'
require 'rails'
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

# Hook up our NPM tasks to the standard uild and release tasks
Rake::Task['build'].enhance(['build:npm'])
Rake::Task['release'].enhance(['release:npm'])

# rubocop:disable Rails/RakeEnvironment
desc 'build javascript assets'
task 'build:npm' do
  sh 'npm install'
  sh 'npm run prepare'
end

desc "Publish javascript assets to npm\n" \
     "To prevent publishing in NPM use e.g. `npm_push=no rake release`"
task 'release:npm' do
  sh 'npm publish' unless %w[n no nil false off 0].include?(ENV["npm_push"].to_s.downcase)
end
# rubocop:enable Rails/RakeEnvironment

load "tasks/blacklight.rake"
load "lib/railties/blacklight.rake"

task default: [:rubocop, :ci]
