# Blacklight customization of the Rake tasks that come with rspec-2, to run
# specs located in alternate location (inside BL plugin), and to provide
# rake tasks for jetty/solr wrapping. 
#
# Same tasks as in ordinary rspec, but prefixed with blacklight:. 
#
# rspec2 keeps it's rake tasks inside it's own code, it doesn't generate them. 
# We had to copy them from there and modify, may have to be done again
# if rspec2 changes a lot, but this code looks relatively cleanish. 
begin
  require 'rspec/core'
  require 'rspec/core/rake_task'
  Rake.application.instance_variable_get('@tasks')['default'].prerequisites.delete('test')
  
  spec_prereq = Rails.configuration.generators.options[:rails][:orm] == :active_record ?  "db:test:prepare" : :noop
  task :noop do; end
  #task :default => :spec
  
  blacklight_spec = File.expand_path("./test_support/spec", Blacklight.root)
  
  # Set env variable to tell our spec/spec_helper.rb where we really are,
  # so it doesn't have to guess with relative path, which will be wrong
  # since we allow spec_dir to be in a remote location. spec_helper.rb
  # needs it before Rails.root is defined there, even though we can
  # oddly get it here, i dunno. 
  ENV['RAILS_ROOT'] = Rails.root
  
  namespace :blacklight do
    
    desc "Run all specs in spec directory (excluding plugin specs)"
    RSpec::Core::RakeTask.new(:spec => spec_prereq) do |t|
      # the user might not have run rspec generator because they don't
      # actually need it, but without an ./.rspec they won't get color,
      # let's insist. 
      t.rspec_opts = "--colour"
      
      # pattern directory name defaults to ./**/*_spec.rb, but has a more concise command line echo
      t.pattern = "#{blacklight_spec}"      
    end
    
    # Don't understand what this does or how to make it use our remote stats_directory
    #task :stats => "spec:statsetup"
    
    namespace :spec do
      [:requests, :models, :controllers, :views, :helpers, :mailers, :lib, :routing].each do |sub|
        desc "Run the code examples in spec/#{sub}"
        RSpec::Core::RakeTask.new(sub => spec_prereq) do |t|
          # the user might not have run rspec generator because they don't
          # actually need it, but without an ./.rspec they won't get color,
          # let's insist. 
          t.rspec_opts = "--colour"
          
          # pattern directory name defaults to ./**/*_spec.rb, but has a more concise command line echo
          t.pattern = "#{blacklight_spec}/#{sub}" 
        end
      end
    
      desc "Run all specs with rcov"
      RSpec::Core::RakeTask.new(:rcov => spec_prereq) do |t|
        t.rcov = true
        # pattern directory name defaults to ./**/*_spec.rb, but has a more concise command line echo
        t.pattern = "#{blacklight_spec}"
        t.rcov_opts = '--colour --exclude /gems/,/Library/,/usr/,lib/tasks,.bundle,config,/lib/rspec/,/lib/rspec-'
      end
      
      # Blacklight. Solr wrapper. for now just for blacklight:spec, plan to
      # provide it for all variants eventually.
      # if you would like to see solr startup messages on STDERR
      # when starting solr test server during functional tests use:
      # 
      #    rake SOLR_CONSOLE=true      
      require File.expand_path('../jetty_solr_server.rb', __FILE__)
      desc "blacklight:solr with jetty/solr launch"
      task :with_solr do    
        # wrap tests with a test-specific Solr server
        # Need to look  up where the test jetty is located
        # from solr.yml, we don't hardcode it anymore. 

        solr_yml_path = locate_path("config", "solr.yml")
        jetty_path = if ( File.exists?( solr_yml_path ))
            solr_config = YAML::load(File.open(solr_yml_path))
            solr_config["test"]["jetty_path"] if solr_config["test"]
        end   
        raise Exception.new("Can't find jetty path to start test jetty. Expect a jetty_path key in config/solr.yml for test environment.") unless jetty_path 

        
        # wrap tests with a test-specific Solr server
        JettySolrServer.new(
          :jetty_home => File.expand_path(jetty_path, Rails.root), 
          :sleep_after_start => 2).wrap do          
            Rake::Task["blacklight:spec"].invoke 
        end             
      end
      
    
      # Don't understand what this does or how to make it use our remote stats_directory.
      # task :statsetup do
        # require 'rails/code_statistics'
        # ::STATS_DIRECTORIES << %w(Model\ specs spec/models) if File.exist?('spec/models')
        # ::STATS_DIRECTORIES << %w(View\ specs spec/views) if File.exist?('spec/views')
        # ::STATS_DIRECTORIES << %w(Controller\ specs spec/controllers) if File.exist?('spec/controllers')
        # ::STATS_DIRECTORIES << %w(Helper\ specs spec/helpers) if File.exist?('spec/helpers')
        # ::STATS_DIRECTORIES << %w(Library\ specs spec/lib) if File.exist?('spec/lib')
        # ::STATS_DIRECTORIES << %w(Mailer\ specs spec/mailers) if File.exist?('spec/mailers')
        # ::STATS_DIRECTORIES << %w(Routing\ specs spec/routing) if File.exist?('spec/routing')
        # ::STATS_DIRECTORIES << %w(Request\ specs spec/requests) if File.exist?('spec/requests')
        # ::CodeStatistics::TEST_TYPES << "Model specs" if File.exist?('spec/models')
        # ::CodeStatistics::TEST_TYPES << "View specs" if File.exist?('spec/views')
        # ::CodeStatistics::TEST_TYPES << "Controller specs" if File.exist?('spec/controllers')
        # ::CodeStatistics::TEST_TYPES << "Helper specs" if File.exist?('spec/helpers')
        # ::CodeStatistics::TEST_TYPES << "Library specs" if File.exist?('spec/lib')
        # ::CodeStatistics::TEST_TYPES << "Mailer specs" if File.exist?('spec/mailers')
        # ::CodeStatistics::TEST_TYPES << "Routing specs" if File.exist?('spec/routing')
        # ::CodeStatistics::TEST_TYPES << "Request specs" if File.exist?('spec/requests')
      # end
    end
  end  
rescue LoadError
  # This rescue pattern stolen from cucumber; rspec didn't need it before since
  # tasks only lived in rspec gem itself, but for Blacklight since we're copying
  # these tasks into BL, we use the rescue so you can still run BL (without
  # these tasks) even if you don't have rspec installed. 
  desc 'rspec rake tasks not available (rspec not installed)'
  task :spec do
    abort 'Rspec rake tasks  not available. Be sure to install rspec gems. '
  end
end
