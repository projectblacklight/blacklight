ZIP_URL = "https://github.com/projectblacklight/blacklight-jetty/archive/v4.10.4.zip"

require 'solr_wrapper'
require 'engine_cart/rake_task'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern =  'spec/**/*_spec.rb'
end

EngineCart.fingerprint_proc = EngineCart.rails_fingerprint_proc

desc "Run test suite"
task :ci => ['blacklight:generate'] do
  SolrWrapper.wrap(port: '8888') do |solr|
    solr.with_collection(name: 'blacklight-core', dir: File.join(File.expand_path("..", File.dirname(__FILE__)), "solr", "conf")) do
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
  task :generate => ['engine_cart:generate'] do
  end

  task :server do
    if File.exists? 'spec/internal'
      within_test_app do
        system "bundle update"
      end
    else
      Rake::Task['engine_cart:generate'].invoke
    end

    SolrWrapper.wrap(port: '8888') do |solr|
      solr.with_collection(name: 'blacklight-core', dir: File.join(File.expand_path("..", File.dirname(__FILE__)), "solr", "conf")) do
        within_test_app do
          system "rake solr:marc:index_test_data"
          system "bundle exec rails s"
        end
      end
    end
  end
end
