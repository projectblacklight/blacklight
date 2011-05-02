namespace :blacklight do
  desc "Run Blacklight cucumber and rspec"
  task :all_tests => ['blacklight:spec:with_solr', 'blacklight:cucumber:with_solr']
end

