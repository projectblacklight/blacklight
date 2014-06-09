gem "blacklight", ">= 5.3.0"

run "bundle install"

# run the blacklight install generator
options = ENV.fetch("BLACKLIGHT_INSTALL_OPTIONS", '--devise --marc --jettywrapper')

generate 'blacklight:install', options

# run the database migrations
rake "db:migrate"

# index some data
if options =~ /jettywrapper/
  rake "jetty:clean"
  rake "jetty:start"
  rake "blacklight:solr:seed"
  rake "jetty:stop"
end
