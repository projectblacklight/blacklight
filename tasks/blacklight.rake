ZIP_URL = "https://github.com/projectblacklight/blacklight-jetty/archive/v4.10.3.zip"

require 'solr_wrapper'
require 'engine_cart/rake_task'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern =  'spec/**/*_spec.rb'
end

desc "Run test suite"
task :ci  do #=> 'blacklight:clean' do
  SolrWrapper.wrap(port: '8888', verbose: true) do |solr|
    solr.with_collection(name: 'blacklight-core', dir: File.join(File.expand_path("..", File.dirname(__FILE__)), "solr", "conf")) do
      Rake::Task["blacklight:fixtures"].invoke
      Rake::Task['blacklight:coverage'].invoke
    end
  end
end

namespace :blacklight do
  desc "Load fixtures"
  task :fixtures => [:generate] do
    within_test_app do
      system "rake solr:marc:index_test_data RAILS_ENV=test"
      abort "Error running fixtures" unless $?.success?
    end
  end

  desc "Run tests with coverage"
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task["spec"].invoke
  end

  desc "Clean out the test rails app"
  task :clean => ['engine_cart:clean'] do
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
