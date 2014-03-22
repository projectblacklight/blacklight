gem "blacklight", ">= 5.3.0"

run "bundle install"

# run the blacklight install generator
generate 'blacklight:install', '--devise --marc --jettywrapper'

# run the database migrations
rake "db:migrate"

# index some data
rake "jetty:clean"

require 'rails'
require 'jettywrapper'

jetty_params = Jettywrapper.load_config('development')
Jettywrapper.wrap(jetty_params) do
  rake "blacklight:solr:seed"
end
