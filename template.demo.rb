# frozen_string_literal: true
gem "blacklight", ">= 6.1"
gem "jettywrapper", ">= 2.0"
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw]

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
  rake "blacklight:index:seed"
  rake "jetty:stop"
end
