namespace :blacklight do
  begin
    require 'cucumber/rake/task'
    require 'rspec/core'
    require 'rspec/core/rake_task'

    desc "Run Blacklight cucumber and rspec, with test solr"
    task :all_tests => :hudson

    desc "Run Blacklight cucumber and rspec, with test solr"
    task :hudson do
      solr_config = Blacklight.solr_yml["test"]
      if solr_config
        jetty_path = solr_config["jetty_path"] 
        uri = URI(solr_config["url"])
        jetty_port = uri.port if ['127.0.0.1', 'localhost'].include? uri.host
      end   
      raise Exception.new("Can't find jetty path to start test jetty. Expect a jetty_path key in config/solr.yml for test environment.") unless jetty_path 

      error = Jettywrapper.wrap(
        :jetty_port => jetty_port,
        :jetty_home => File.expand_path(jetty_path, Rails.root), 
        :sleep_after_start => 2) do          
          Rake::Task["blacklight:spec"].invoke 
          Rake::Task["blacklight:cucumber"].invoke 
      end             

      raise "test failures: #{error}" if error
    end
    
    namespace :all_tests do
      task :rcov do
      desc "Run Blacklight rspec and cucumber tests with rcov"
      solr_config = Blacklight.solr_yml["test"]
      if solr_config
        jetty_path = solr_config["jetty_path"] 
        uri = URI(solr_config["url"])
        jetty_port = uri.port if ['127.0.0.1', 'localhost'].include? uri.host
      end   
      raise Exception.new("Can't find jetty path to start test jetty. Expect a jetty_path key in config/solr.yml for test environment.") unless jetty_path 

      rm "blacklight-coverage.data" if File.exist?("blacklight-coverage.data")
      error = Jettywrapper.wrap(
        :jetty_port => jetty_port,
        :jetty_home => File.expand_path(jetty_path, Rails.root), 
        :sleep_after_start => 2) do          
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
