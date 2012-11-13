namespace :blacklight do
  begin
    require 'cucumber/rake/task'
    require 'rspec/core'
    require 'rspec/core/rake_task'

    desc "Run Blacklight cucumber and rspec, with test solr"
    task :all_tests => :hudson

    desc "Run Blacklight cucumber and rspec, with test solr"
    task :hudson do
   
      error = Jettywrapper.wrap(Jettywrapper.load_config) do          
          Rake::Task["blacklight:spec"].invoke 
          Rake::Task["blacklight:cucumber"].invoke 
      end             

      raise "test failures: #{error}" if error
    end
    
    namespace :all_tests do
      task :rcov do
      desc "Run Blacklight rspec and cucumber tests with rcov"

      rm "blacklight-coverage.data" if File.exist?("blacklight-coverage.data")
      error = Jettywrapper.wrap(Jettywrapper.load_config) do          
          Rake::Task["blacklight:spec:rcov"].invoke 
          Rake::Task["blacklight:cucumber:rcov"].invoke 
      end             
      raise "test failures: #{error}" if error
    end
  end
    
  rescue LoadError
    desc "Not available! (cucumber and rspec not avail)"
    task :all_tests do
      abort 'Not available. Both cucumber and rspec need to be installed to run blacklight:all_tests'
    end
  end
end
