# frozen_string_literal: true

gem "blacklight", ">= 6.1"

run "bundle install"

# run the blacklight install generator
options = ENV.fetch("BLACKLIGHT_INSTALL_OPTIONS", '--devise --marc --solr_version=latest')

generate 'blacklight:install', options

# run the database migrations
rake "db:migrate"
