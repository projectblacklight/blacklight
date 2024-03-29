# frozen_string_literal: true

gem 'blacklight', '>= 7.0'

after_bundle do
  # run the blacklight install generator
  options = ENV.fetch("BLACKLIGHT_INSTALL_OPTIONS", '--devise --marc')

  generate 'blacklight:install', options

  # run the database migrations
  rake "db:migrate"
end
