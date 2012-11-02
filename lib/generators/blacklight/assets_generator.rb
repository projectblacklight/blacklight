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
      unless IO.read("app/assets/stylesheets/application.css").include?("Blacklight")
        insert_into_file "app/assets/stylesheets/application.css", :after => "/*" do
  %q{
 *= require 'blacklight/blacklight'         
 *}
        end
      end

      unless IO.read("app/assets/javascripts/application.js").include?('blacklight/blacklight')
        insert_into_file "app/assets/javascripts/application.js", :after => "//= require jquery_ujs" do
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
