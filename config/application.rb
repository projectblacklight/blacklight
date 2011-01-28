require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module BlacklightApp
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # DHF: old bug with having sub-directories named the same as classes 
    # please see https://rails.lighthouseapp.com/projects/8994/tickets/2459-activesupportdependenciesload_missing_constant-fails-to-load
    #    config.autoload_paths << File.join(config.root, "lib/blacklight")

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]

    # Added from old environment.rb
    config.action_mailer.delivery_method = :sendmail 
    config.log_level = :debug
    config.time_zone = 'UTC'


    config.session_store(:session_key, '_blacklight_session')
    config.session_store(:secret, '3e37cf3b7a9a3359f437aac207241fd25c2e2a107f85b2e6d32e0b5e3795e75fdb094b9d045d8c40e9ae2b38063c8926ef01b1e03946652eadf96c653d6effa9')
    
    config.after_initialize do
      require 'will_paginate_link_renderer'   # in local ./lib
      require 'taggable_pagination'           # in local ./lib
      Blacklight.init

      # Content types used by Marc Document extension, possibly among others.
      # Registering a unique content type with 'register' (rather than
      # register_alias) will allow content-negotiation for the format. 
      Mime::Type.register_alias "text/plain", :refworks_marc_txt
      Mime::Type.register_alias "text/plain", :openurl_kev
      Mime::Type.register "application/x-endnote-refer", :endnote
      Mime::Type.register "application/marc", :marc
      Mime::Type.register "application/marcxml+xml", :marcxml, 
      ["application/x-marc+xml", "application/x-marcxml+xml", 
       "application/marc+xml"]

      puts  "This application has Blacklight version #{Blacklight.version} installed" if Blacklight.version
    end
  
    # the blacklight_config file configures objects, creates a config hash etc..
    # Rails will only load this file once.
    # Development mode (cache_classes = false) experiences problems though.
    # The most obvious symptom is where the application
    # works fine for the first request, but sub-sequent requests fail.
    # Using require_dependency inside of to_prepare
    # will load this file for every request,
    # when config.cache_classes == false.
    # if config.cache_classes == true (production mode)
    # then this file is not continously reloaded as the code is cached. 
    # DHF - JRUBY Not sure this is necissary anymore and it's giving me an error.
#    config.to_prepare do
#      require_dependency File.expand_path('config/initializers/blacklight_config.rb') unless config.cache_classes
#    end
  end

  unless File.exists? File.join(Rails.root, 'config', 'initializers', 'blacklight_config.rb')
    raise "Blacklight requires a config/initializers/blacklight_config.rb file."
  end
  
  require 'blacklight'
end
