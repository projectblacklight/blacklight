#
# list application gems here...
# list testing gems in the plugin's config/environment.rb file
#   - this will prevent users from having to install testing gems
#

config.gem "authlogic", :version=>'2.1.2'

config.gem 'marc', :version=>'0.3.0'
config.gem 'libxml-ruby', :lib=>'libxml', :version=>'1.1.3'
config.gem 'ruby-xslt', :lib=>'xml/xslt', :version=>'0.9.6'

config.gem 'nokogiri', :version=>'1.3.3'

config.gem 'mislav-will_paginate', :lib=>'will_paginate', :version=>'2.3.8', :source=>'http://gems.github.com'

config.gem 'rsolr', :lib=>'rsolr', :version=>'0.9.6', :source=>'http://gemcutter.org'
config.gem 'rsolr-ext', :lib=>'rsolr-ext', :version=>'0.9.6.4', :source=>'http://gemcutter.org'

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
