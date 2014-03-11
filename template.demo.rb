gem "blacklight"

# copy the blacklight jetty.yml into their app
create_file "config/jetty.yml", File.read(File.expand_path('../config/jetty.yml', __FILE__))

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
