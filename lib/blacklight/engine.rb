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
      # Check for a blacklight_install envrionment variable - if set then blacklight
      # is actively being installed and we should not attempt an init at this time.
      if defined?(Rails::Server)
        Blacklight.init
      end      
    end

    # This makes our rake tasks visible.
    rake_tasks do
      Dir.chdir(File.expand_path(File.join(File.dirname(__FILE__), '..'))) do
        Dir.glob(File.join('railties', '*.rake')).each do |railtie|
          load railtie
        end
      end
    end

  end
end
