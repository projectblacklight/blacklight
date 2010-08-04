#
# list application gems here...
# list testing gems in the plugin's config/environment.rb file
#   - this will prevent users from having to install testing gems
#

config.gem "rails", :version=>'2.3.5'

config.gem "authlogic", :version=>'2.1.2'

config.gem 'marc', :version=>'0.3.0'

config.gem 'will_paginate', :lib=>'will_paginate', :version=>'2.3.11', :source=>'http://gemcutter.org'

config.gem 'rsolr', :lib=>'rsolr', :version=>'0.12.1', :source=>'http://gemcutter.org'
config.gem 'rsolr-ext', :lib=>'rsolr-ext', :version=>'0.12.1', :source=>'http://gemcutter.org'

if defined? JRUBY_VERSION
  config.gem 'activerecord-jdbc-adapter', :lib=>'jdbc_adapter', :version=>'0.9.2'
  config.gem 'jdbc-sqlite3', :lib=>'jdbc/sqlite3', :version => '3.6.3.054'
  config.gem 'activerecord-jdbcsqlite3-adapter', :lib=>'active_record/connection_adapters/jdbcsqlite3_adapter', :version => '0.9.2'
  config.gem 'ActiveRecord-JDBC', :lib=>'jdbc_adapter', :version => '0.5'
end

config.after_initialize do
  require 'will_paginate_link_renderer'   # in local ./lib
  require 'taggable_pagination'           # in local ./lib
  Blacklight.init

  # Content types used by Marc Document extension, possibly among others.
  # Registering a unique content type with 'register' (rather than
  # register_alias) will allow content-negotiation for the format. 
  Mime::Type.register_alias "text/plain", :refworks_marc_txt
  Mime::Type.register_alias "text/plain", :openurl_kev
  Mime::Type.register "application/x-endnote-refer", :endnote
  Mime::Type.register "application/marc", :marc
  Mime::Type.register "application/marcxml+xml", :marcxml, 
        ["application/x-marc+xml", "application/x-marcxml+xml", 
         "application/marc+xml"]

  puts  "This application has Blacklight version #{Blacklight.version} installed" if Blacklight.version
end

# the blacklight_config file configures objects, creates a config hash etc..
# Rails will only load this file once.
# Development mode (cache_classes = false) experiences problems though.
# The most obvious symptom is where the application
# works fine for the first request, but sub-sequent requests fail.
# Using require_dependency inside of to_prepare
# will load this file for every request,
# when config.cache_classes == false.
# if config.cache_classes == true (production mode)
# then this file is not continously reloaded as the code is cached. 
config.to_prepare do
  require_dependency File.expand_path('config/initializers/blacklight_config.rb') unless config.cache_classes
end

unless File.exists? File.join(Rails.root, 'config', 'initializers', 'blacklight_config.rb')
  raise "Blacklight requires a config/initializers/blacklight_config.rb file."
end

require 'blacklight'
