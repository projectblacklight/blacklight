# frozen_string_literal: true

require 'view_component'

module Blacklight
  class Engine < Rails::Engine
    engine_name "blacklight"

    # BlacklightHelper is needed by all helpers, so we inject it
    # into action view base here.
    initializer 'blacklight.helpers' do
      config.after_initialize do
        ActionView::Base.include BlacklightHelper
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

    initializer "blacklight.assets.precompile" do
      # rubocop:disable Lint/ConstantDefinitionInBlock
      PRECOMPILE_ASSETS = %w(favicon.ico blacklight/blacklight.js blacklight/blacklight.js.map).freeze
      # rubocop:enable Lint/ConstantDefinitionInBlock

      # When Rails has been generated in API mode, it does not have sprockets available
      if Rails.application.config.respond_to?(:assets)
        Rails.application.config.assets.precompile += PRECOMPILE_ASSETS
      end
    end

    initializer "blacklight.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.assets.precompile += Dir.glob(Engine.root.join("app/javascript/**/*.js"))
        app.config.assets.paths << Engine.root.join('app', 'javascript')
        app.config.importmap.paths << Engine.root.join("config/importmap.rb")
      end
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
