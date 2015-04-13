# -*- encoding : utf-8 -*-
module Blacklight
  class Assets < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
  
    def assets
      copy_file "blacklight.css.scss", "app/assets/stylesheets/blacklight.css.scss"

      return if has_blacklight_assets?

      marker = if turbolinks?
                 '//= require turbolinks'
               else
                 '//= require jquery_ujs'
               end

      insert_into_file "app/assets/javascripts/application.js", :after => marker do
<<-EOF
//
// Required by Blacklight
//= require blacklight/blacklight
EOF
      end

    end

    private

    def turbolinks?
      @turbolinks ||= IO.read("app/assets/javascripts/application.js").include?('turbolinks')
    end

    def has_blacklight_assets?
      IO.read("app/assets/javascripts/application.js").include?('blacklight/blacklight')
    end
  end
end