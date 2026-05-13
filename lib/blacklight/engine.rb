# frozen_string_literal: true

require 'view_component'

module Blacklight
  class Engine < Rails::Engine
    engine_name "blacklight"

    config.before_configuration do
      # see https://github.com/fxn/zeitwerk#for_gem
      # Blacklight puts a generator into LOCAL APP lib/generators, so tell
      # zeitwerk to ignore the whole directory? If we're using a recent
      # enough version of Rails to have zeitwerk config
      #
      # See: https://github.com/cbeer/engine_cart/issues/117
      if Rails.try(:autoloaders).try(:main).respond_to?(:ignore)
        Rails.autoloaders.main.ignore(Rails.root.join('lib/generators'))
      end
    end

    config.after_initialize do
      Blacklight::Configuration.initialize_default_configuration
    end

    # This makes our rake tasks visible.
    rake_tasks do
      Dir.chdir(File.expand_path(File.join(File.dirname(__FILE__), '..'))) do
        Dir.glob(File.join('railties', '*.rake')).each do |railtie|
          load railtie
        end
      end
    end

    PRECOMPILE_ASSETS = %w(favicon.ico blacklight/blacklight.js blacklight/blacklight.js.map blacklight/blacklight.esm.js blacklight/blacklight.esm.js.map).freeze

    initializer "blacklight.assets.precompile" do |app|
      # When Rails has been generated in API mode, it does not have sprockets available
      next unless app.config.respond_to?(:assets)

      app.config.assets.paths << Engine.root.join("app/javascript")
      app.config.assets.precompile += Blacklight::Engine::PRECOMPILE_ASSETS
    end

    initializer "blacklight.importmap", before: "importmap" do |app|
      app.config.importmap.paths << Engine.root.join("config/importmap.rb") if app.config.respond_to?(:importmap)
    end

    bl_global_config = OpenStructWithHashAccess.new

    bl_global_config.sms_mappings = {
      'Virgin' => 'vmobl.com',
      'AT&T' => 'txt.att.net',
      'Verizon' => 'vtext.com',
      'Nextel' => 'messaging.nextel.com',
      'Sprint' => 'messaging.sprintpcs.com',
      'T Mobile' => 'tmomail.net',
      'Alltel' => 'message.alltel.com',
      'Cricket' => 'mms.mycricket.com',
      'Google Fi' => 'msg.fi.google.com'
    }

    bl_global_config.bookmarks_http_method = :post

    bl_global_config.email_regexp = defined?(Devise) ? Devise.email_regexp : /\A[^@\s]+@[^@\s]+\z/

    bl_global_config.facet_missing_param = '[* TO *]'

    # These options are passed through to the kaminari #paginate helper
    # https://www.rubydoc.info/gems/kaminari/1.2.2#helpers
    bl_global_config.default_pagination_options = {
      theme: 'blacklight',
      outer_window: 2
    }

    bl_global_config.search_params_permitted_classes = [ActiveSupport::HashWithIndifferentAccess, Symbol]

    # Anything that goes into Blacklight::Engine.config is stored as a class
    # variable on Railtie::Configuration.  we're going to encapsulate all the
    # Blacklight specific stuff in this single struct:
    Blacklight::Engine.config.blacklight = bl_global_config

    config.action_dispatch.rescue_responses["Blacklight::Exceptions::RecordNotFound"] = :not_found
  end
end
