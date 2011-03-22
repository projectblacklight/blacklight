# lib/blacklight/engine.rb
require "blacklight"
require "rails"

module Blackight
  class Engine < Rails::Engine

    # BlacklightHelper is needed by all helpers, so we inject it
    # into action view base here. 
    initializer 'blacklight.helpers' do |app|
      ActionView::Base.send :include, BlacklightHelper
    end

    # Go ahead and innitialize Blacklight at the very end of the rails 
    # innitilization process.  
    # See: http://www.cowboycoded.com/2010/08/02/hooking-in-your-rails-3-engine-or-railtie-initializer-in-the-right-place/
    initializer 'blacklight.init', :after=> :disable_dependency_loading do |app|
      # Note, check for configuration files before calling init, 
      # otherwise we can't generate these files with the Generator
      # and we can't tell at this point if we are begin run as a generator
      # or not (at least, I didn't see a way)
      Blacklight.init if File.exists?(Blacklight.solr_file)      
    end

    # This makes our rake tasks visible.
    rake_tasks do
      load "railties/blacklight.rake"
      load "railties/solr_marc.rake"
    end

  end
end
