# -*- encoding : utf-8 -*-
module Blacklight
  class Assets < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
  
    def assets
      copy_file "blacklight.css.scss", "app/assets/stylesheets/blacklight.css.scss"

      unless IO.read("app/assets/javascripts/application.js").include?('blacklight/blacklight')
        marker = IO.read("app/assets/javascripts/application.js").include?('turbolinks') ?
          '//= require turbolinks' : "//= require jquery_ujs"
        insert_into_file "app/assets/javascripts/application.js", :after => marker do
  %q{
//
// Required by Blacklight
//= require blacklight/blacklight}          
        end
      end

    end
  end
end
