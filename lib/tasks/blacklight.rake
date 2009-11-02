namespace :build do
  
  def release_name
    version = ENV['RELEASE_VERSION'].to_s.empty? ? nil : ENV['RELEASE_VERSION']
    raise "A RELEASE_VERSION is required." unless version
    "release-#{version}"
  end
  
  # remove remote branch:
  #   git push origin :heads/<branch-name>
  # remove local branch
  #   git branch -D <branch-name>
  # remove remote tag:
  #   git push origin :refs/tags/<tag-name>
  # remove local tag:
  #   git tag -d <tag-name>
  desc "Creates a new modified branch and tag using <release-$RELEASE_VERSION>"
  task :release do
    name = release_name
    `git branch #{name}`
    template = File.read "template.rb"
    File.open("template.rb", "w") {|f| f.puts template.sub(/tag = branch = nil/, "tag = branch = '#{name}'") }
    `git commit -a -m 'changed template to work with #{name}'`
    `git push origin #{name}`
    tag_cmd = "git tag -a -m 'tag for #{name}' #{name} && git push origin tag #{name}"
    `#{tag_cmd}`
    `cd ../blacklight-jetty && #{tag_cmd}`
    `cd ../blacklight-data && #{tag_cmd}`
  end
  
  task :undo_release do
    name = release_name
    branch_cmd = "git push origin :heads/#{name} && git branch -D #{name}"
    tag_cmd = "git tag -d #{name} && git push origin :refs/tags/#{name}"
    `#{branch_cmd} && #{tag_cmd}`
    `cd ../blacklight-jetty && #{tag_cmd}`
    `cd ../blacklight-data && #{tag_cmd}`
  end
  
end

# Rake tasks for Blacklight plugin

desc "Runs db:migrate then spec for Cruise Control."
task :ccspec => ["db:migrate:reset", "solr:spec"]

desc "Runs db:migrate then features for Cruise Control."
task :ccfeatures => ["db:migrate:reset", "solr:features"]


# if you would like to see solr startup messages on STDERR
# when starting solr test server during functional tests use:
# 
#    rake SOLR_CONSOLE=true
require File.expand_path(File.dirname(__FILE__) + '/../../spec/lib/test_solr_server.rb')


SOLR_PARAMS = {
  :quiet => ENV['SOLR_CONSOLE'] ? false : true,
  :jetty_home => ENV['SOLR_JETTY_HOME'] || File.expand_path('./jetty'),
  :jetty_port => ENV['SOLR_JETTY_PORT'] || 8888,
  :solr_home => ENV['SOLR_HOME'] || File.expand_path('./jetty/solr')
}

namespace :solr do
  
  desc "Calls RSpec Examples wrapped in the test instance of Solr"
  task :spec do
    # wrap tests with a test-specific Solr server
    error = TestSolrServer.wrap(SOLR_PARAMS) do
rm_f "coverage.data"
      Rake::Task["rake:spec"].invoke 
      #puts `ps aux | grep start.jar` 
    end
    raise "test failures: #{error}" if error
  end

  desc "Calls Cucumber Features wrapped in the test instance of Solr"
  task :features do
    # wrap tests with a test-specific Solr server
    error = TestSolrServer.wrap(SOLR_PARAMS) do
      Rake::Task["rake:features"].invoke 
      #puts `ps aux | grep start.jar` 
    end
    raise "test failures: #{error}" if error
  end
end
