module Blacklight
  class Engine < Rails::Engine
    engine_name "blacklight"

    require 'bootstrap-sass'
    require 'blacklight/rails/routes'
    config.autoload_paths += %W(
      #{config.root}/lib
    )
    

    # BlacklightHelper is needed by all helpers, so we inject it
    # into action view base here. 
    initializer 'blacklight.helpers' do |app|
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
    
    initializer "blacklight.secret_key" do |app|
      if app.respond_to?(:secrets)
        Blacklight.secret_key ||= app.secrets.secret_key_base
      elsif app.config.respond_to?(:secret_key_base)
        Blacklight.secret_key ||= app.config.secret_key_base
      end
    end

  end
end
