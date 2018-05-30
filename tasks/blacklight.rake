require 'solr_wrapper'
require 'engine_cart/rake_task'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

EngineCart.fingerprint_proc = EngineCart.rails_fingerprint_proc

desc "Run test suite"
task ci: ['blacklight:generate'] do
  SolrWrapper.wrap do |solr|
    solr.with_collection do
      within_test_app do
        system "RAILS_ENV=test rake blacklight:index:seed"
      end
      Rake::Task['blacklight:coverage'].invoke
    end
  end
end

namespace :blacklight do
  desc "Run tests with coverage"
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task["spec"].invoke
  end

  desc "Create the test rails app"
  task generate: ['engine_cart:generate'] do
  end

  namespace :internal do
    task seed: ['engine_cart:generate'] do
      within_test_app do
        system "bundle exec rake blacklight:index:seed"
      end
    end
  end

  desc 'Run Solr and Blacklight for interactive development'
  task :server, [:rails_server_args] do |_t, args|
    if File.exist? EngineCart.destination
      within_test_app do
        system "bundle update"
      end
    else
      Rake::Task['engine_cart:generate'].invoke
    end

    SolrWrapper.wrap do |solr|
      solr.with_collection do
        Rake::Task['blacklight:internal:seed'].invoke

        within_test_app do
          system "bundle exec rails s #{args[:rails_server_args]}"
        end
      end
    end
  end
end
