config.gem "authlogic"
#config.gem 'mwmitchell-rsolr-ext', :version=>'0.7.35', :lib=>'rsolr-ext', :source=>'http://github.com'

# Load up the vendorized gems:
[
  'mislav-will_paginate-2.3.8/lib/will_paginate.rb',
  'mwmitchell-rsolr-0.8.8/lib/rsolr.rb',
  'mwmitchell-rsolr-ext-0.7.35/lib/rsolr-ext.rb',
  'marc-0.2.2/lib/marc.rb'
].each do |gem_file|
  # add the lib dir of each gem to the load path, which is the variable $:
  $: << File.join(File.dirname(__FILE__), 'vendor', 'gems', File.dirname(gem_file))
  # now require the gem file, based on the last path added to $:
  require File.join($:.last, File.basename(gem_file))
end

config.after_initialize do
  require 'will_paginate_link_renderer'   # in local ./lib
  require 'taggable_pagination'           # in local ./lib
  Blacklight.init
end