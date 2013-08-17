ZIP_URL = "https://github.com/projectblacklight/blacklight-jetty/archive/v4.0.0.zip"
APP_ROOT = File.expand_path("../..", __FILE__)

TEST_APP_TEMPLATES = 'spec/test_app_templates'
TEST_APP = 'spec/internal'

require 'jettywrapper'
require 'rspec/core/rake_task'


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
    Rake::Task["blacklight:spec"].invoke
  end

  desc "Run specs"
  task :spec => [:generate] do |t|
    spec_options = ENV['SPEC'] ? " SPEC=#{File.join(GEM_ROOT, ENV['SPEC'])}" : ''
    within_test_app do
      system "rake blacklight_test_app:spec#{spec_options}"
      abort "Error running spec" unless $?.success?
    end
  end

  desc "Clean out the test rails app"
  task :clean do
    puts "Removing sample rails app"
    `rm -rf #{TEST_APP}`
  end

  desc "Create the test rails app"
  task :generate do
    unless File.exists?('spec/internal/Rakefile')
      puts "Generating rails app"
      `rails new #{TEST_APP}`
      puts "Copying gemfile"
      open("#{TEST_APP}/Gemfile", 'a') do |f|
        f.write File.read(TEST_APP_TEMPLATES + "/Gemfile.extra")
        f.write "gem 'blacklight', :path => '../../'" 
      end
      puts "Copying generator"
      `cp -r #{TEST_APP_TEMPLATES}/lib/generators #{TEST_APP}/lib`
      within_test_app do
        puts "Bundle install"
        `bundle install`
        puts "running test_app_generator"
        system "rails generate test_app"

        puts "running migrations"
        puts `rake db:migrate db:test:prepare`
      end
    end
    puts "Done generating test app"
  end



end

def within_test_app
  FileUtils.cd(TEST_APP)
  Bundler.with_clean_env do
    yield
  end
  FileUtils.cd(APP_ROOT)
end
