#
# list application gems here...
# list testing gems in the plugin's config/environment.rb file
#   - this will prevent users from having to install testing gems
#

config.gem "authlogic", :version=>'2.1.2'

config.gem 'marc', :version=>'0.3.0'

config.gem 'will_paginate', :lib=>'will_paginate', :version=>'2.3.11', :source=>'http://gemcutter.org'

config.gem 'rsolr', :lib=>'rsolr', :version=>'0.11.0', :source=>'http://gemcutter.org'
config.gem 'rsolr-ext', :lib=>'rsolr-ext', :version=>'0.11.2', :source=>'http://gemcutter.org'

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
  Mime::Type.register_alias "text/plain", :refworks
  Mime::Type.register_alias "application/x-endnote-refer", :endnote
end

unless File.exists? File.join(Rails.root, 'config', 'initializers', 'blacklight_config.rb')
  raise "Blacklight requires a config/initializers/blacklight_config.rb file."
end

# loading these here prevents Rails from reloading in development mode -- which erases Blacklight.config
# because config/initializers/* are only loaded at boot time.
require 'rsolr-ext'
require 'blacklight'