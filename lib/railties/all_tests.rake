namespace :blacklight do
  begin
    require 'cucumber/rake/task'
    require 'rspec/core'
    require 'rspec/core/rake_task'

    desc "Run Blacklight cucumber and rspec, with test solr"
    task :all_tests => ['blacklight:spec:with_solr', 'blacklight:cucumber:with_solr']
    
    namespace :all_tests do
      desc "Run Blacklight rspec and cucumber tests with rcov"
      rm "blacklight-coverage.data" if File.exist?("blacklight-coverage.data")
      task :rcov => ['blacklight:spec:rcov', 'blacklight:cucumber:rcov']
    end
    
  rescue LoadError
    desc "Not available! (cucumber and rspec not avail)"
    task :all_tests do
      abort 'Not available. Both cucumber and rspec need to be installed to run blacklight:all_tests'
    end
  end
end

