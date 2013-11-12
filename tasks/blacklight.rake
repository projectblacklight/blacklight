ZIP_URL = "https://github.com/projectblacklight/blacklight-jetty/archive/v4.0.0.zip"

require 'jettywrapper'
require 'engine_cart/rake_task'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern =  'spec/**/*_spec.rb'
end

task :ci => 'jetty:clean' do
  ENV['environment'] = "test"
  jetty_params = Jettywrapper.load_config
  jetty_params[:startup_wait]= 60
  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task["blacklight:fixtures"].invoke
    Rake::Task['blacklight:coverage'].invoke
  end
  raise "test failures: #{error}" if error
  # Only create documentation if the tests have passed
  #Rake::Task["active_fedora:doc"].invoke
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
end

