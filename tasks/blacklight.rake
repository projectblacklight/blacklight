# frozen_string_literal: true

require 'engine_cart/rake_task'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

require 'solr_wrapper'
require 'open3'

def system_with_error_handling(*args)
  Open3.popen3(*args) do |stdout, stderr, status, _thread|
    puts stdout.read
    raise "Unable to run #{args.inspect}: #{stderr.read}" unless status.success?
  end
end

def with_solr
  if system('docker-compose')
    begin
      puts "Starting Solr"
      system_with_error_handling "docker-compose up -d solr"
      yield
    ensure
      puts "Stopping Solr"
      system_with_error_handling "docker-compose stop solr"
    end
  else
    SolrWrapper.wrap do |solr|
      solr.with_collection do
        yield
      end
    end
  end
end

# rubocop:disable Rails/RakeEnvironment
desc "Run test suite"
task :ci do
  with_solr do
    Rake::Task['blacklight:internal:seed'].invoke
    Rake::Task['blacklight:coverage'].invoke
  end
end

namespace :blacklight do
  desc "Run tests with coverage"
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task["spec"].invoke
  end

  namespace :internal do
    desc 'Index seed data in test app'
    task seed: ['engine_cart:generate'] do
      within_test_app do
        system "bin/rake blacklight:index:seed"
      end
    end
  end

  desc 'Run Solr and Blacklight for interactive development'
  task :server, [:rails_server_args] => ['engine_cart:generate'] do |_t, args|
    with_solr do
      Rake::Task['blacklight:internal:seed'].invoke

      within_test_app do
        puts "Starting Blacklight (Rails server)"
        system "bin/rails s #{args[:rails_server_args]}"
      rescue Interrupt
        # We expect folks to Ctrl-c to stop the server so don't barf at them
        puts "\nStopping Blacklight (Rails server)"
      end
    end
  end
end
# rubocop:enable Rails/RakeEnvironment
