namespace :blacklight do
  begin
    require 'rspec/core'
    require 'rspec/core/rake_task'

    desc "Run Blacklight rspec, with test solr"
    task :all_tests => :hudson

    desc "Run Blacklight rspec, with test solr"
    task :hudson do
      Rails.env = 'test' unless ENV['RAILS_ENV']

      error = Jettywrapper.wrap(Jettywrapper.load_config) do
          Rake::Task["blacklight:spec"].invoke 
      end

      raise "test failures: #{error}" if error
    end
    
    namespace :all_tests do
      task :rcov do
      desc "Run Blacklight rspec tests with rcov"

      rm "blacklight-coverage.data" if File.exist?("blacklight-coverage.data")
      Rails.env = 'test' unless ENV['RAILS_ENV']
      error = Jettywrapper.wrap(Jettywrapper.load_config) do          
          Rake::Task["blacklight:spec:rcov"].invoke 
      end             
      raise "test failures: #{error}" if error
    end
  end
    
  rescue LoadError
    desc "Not available! (rspec not avail)"
    task :all_tests do
      abort 'Not available. Rspec needs to be installed to run blacklight:all_tests'
    end
  end
end
