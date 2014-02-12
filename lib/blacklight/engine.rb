module Blacklight
  class Engine < Rails::Engine
    engine_name "blacklight"

    require 'bootstrap-sass'
    require 'blacklight/rails/routes'

    config.inject_blacklight_helpers = true

    # BlacklightHelper is needed by all helpers, so we inject it
    # into action view base here. 
    initializer 'blacklight.helpers' do |app|
      Blacklight::Engine.add_blacklight_helper! if Blacklight::Engine.config.inject_blacklight_helpers
    end

    def self.add_blacklight_helper!
      ActionView::Base.send :include, BlacklightHelper
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