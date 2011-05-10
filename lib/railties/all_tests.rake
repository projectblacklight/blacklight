namespace :blacklight do
  desc "Run Blacklight cucumber and rspec"
  task :all_tests => ['blacklight:spec:with_solr', 'blacklight:cucumber:with_solr']

  namespace :all_tests do
    desc "Run Blacklight rspec and cucumber tests with rcov"
    rm "blacklight-coverage.data" if File.exist?("blacklight-coverage.data")
    task :rcov => ['blacklight:spec:rcov', 'blacklight:cucumber:rcov']
  end
end

