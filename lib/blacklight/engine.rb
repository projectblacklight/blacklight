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

    initializer "blacklight.assets.precompile" do
      # rubocop:disable Lint/ConstantDefinitionInBlock
      PRECOMPILE_ASSETS = %w(favicon.ico blacklight/blacklight.js blacklight/blacklight.js.map).freeze
      # rubocop:enable Lint/ConstantDefinitionInBlock

      # When Rails has been generated in API mode, it does not have sprockets available
      if Rails.application.config.respond_to?(:assets)
        Rails.application.config.assets.precompile += PRECOMPILE_ASSETS
      end
    end

    Blacklight::Engine.config.sms_mappings = {
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

    config.bookmarks_http_method = :post

    config.email_regexp = defined?(Devise) ? Devise.email_regexp : /\A[^@\s]+@[^@\s]+\z/

    config.action_dispatch.rescue_responses["Blacklight::Exceptions::RecordNotFound"] = :not_found

    config.enable_search_bar_autofocus = false

    config.facet_missing_param = '[* TO *]'
  end
end
