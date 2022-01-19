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

    # This makes our rake tasks visible.
    rake_tasks do
      Dir.chdir(File.expand_path(File.join(File.dirname(__FILE__), '..'))) do
        Dir.glob(File.join('railties', '*.rake')).each do |railtie|
          load railtie
        end
      end
    end

    initializer "blacklight.assets.precompile" do |app|
      # When Rails has been generated in API mode, it does not have sprockets available
      if defined? Sprockets
        app.config.assets.precompile += %w(favicon.ico)
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

    # Anything that goes into Blacklight::Engine.config is stored as a class
    # variable on Railtie::Configuration.  we're going to encapsulate all the
    # Blacklight specific stuff in this single struct:
    Blacklight::Engine.config.blacklight = bl_global_config

    config.action_dispatch.rescue_responses["Blacklight::Exceptions::RecordNotFound"] = :not_found

    config.facet_missing_param = '[* TO *]'
  end
end
