# -*- encoding : utf-8 -*-

module Blacklight
  class Engine < Rails::Engine

    require 'bootstrap-sass'

    # BlacklightHelper is needed by all helpers, so we inject it
    # into action view base here. 
    initializer 'blacklight.helpers' do |app|
      ActionView::Base.send :include, BlacklightHelper
    end
    
    # Expose Jquery-ui image assets so they are precompiled
    # to root path so jquery-ui css compiled into asset pipeline
    # can find them. 
    # http://bibwild.wordpress.com/2011/12/08/jquery-ui-css-and-images-and-rails-asset-pipeline/
    #
    # Sorry, we end up prepending jquery-ui asset path before ALL paths, even
    # application, no easy way to insert em before the gem paths but after
    # the app paths. 
    #
    # You may want to disable this if you want to supply your own theme, just set
    #     Blacklight::Engine.config.jquery_ui_images = false
    # in config/appliction.rb or other pre-initializer control point. 
    config.before_configuration do
      config.jquery_ui_images = true
    end
    initializer "blacklight.jquery_ui_images",
            :group => :all,
            :after => :append_assets_path do
      if config.jquery_ui_images
        Rails.application.config.assets.paths.unshift self.class.root.join("app", "assets", "stylesheets", "jquery", "ui-lightness").to_s
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
