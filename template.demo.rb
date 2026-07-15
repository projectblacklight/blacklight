# frozen_string_literal: true

gem 'blacklight', '>= 7.0'

after_bundle do
  # run the blacklight install generator
  default_authentication_option = Rails.gem_version >= Gem::Version.new('8.0.0') ? '--authentication' : '--devise'
  options = ENV.fetch("BLACKLIGHT_INSTALL_OPTIONS", "#{default_authentication_option} --marc")

  generate 'blacklight:install', options

  # run the database migrations
  rake "db:migrate"
end
