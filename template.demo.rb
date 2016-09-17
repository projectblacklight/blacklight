gem "blacklight", ">= 6.1"

run "bundle install"

# run the blacklight install generator
options = ENV.fetch("BLACKLIGHT_INSTALL_OPTIONS", '--devise --marc --solr_version=latest')

generate 'blacklight:install', options

# run the database migrations
rake "db:migrate"

# index some data
if options =~ /solr_version/
  require 'solr_wrapper'

  SolrWrapper.wrap do
    rake "blacklight:index:seed"
  end
end
