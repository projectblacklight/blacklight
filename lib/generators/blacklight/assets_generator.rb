# -*- encoding : utf-8 -*-
# Copy Blacklight assets to public folder in current app. 
# If you want to do this on application startup, you can
# add this next line to your one of your environment files --
# generally you'd only want to do this in 'development', and can
# add it to environments/development.rb:
#       require File.join(Blacklight.root, "lib", "generators", "blacklight", "assets_generator.rb")
#       Blacklight::Assets.start(["--force", "--quiet"])


# Need the requires here so we can call the generator from environment.rb
# as suggested above. 
require 'rails/generators'
require 'rails/generators/base'
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

      directory("../../../../app/assets/images/blacklight", "app/assets/images/blacklight")
    end
  end
end
