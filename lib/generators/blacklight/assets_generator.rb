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
      if use_asset_pipeline?
        insert_into_file "app/assets/stylesheets/application.css", :after => "/*" do
%q{
 *
 * Required by Blacklight
 *= require 'yui'
 *= require 'jquery/ui-lightness/jquery-ui-1.8.1.custom.css'
 *= require 'blacklight/blacklight'         
}
        end

        insert_into_file "app/assets/javascripts/application.js", :after => "//= require jquery_ujs" do
%q{
// Required by Blacklight
//= require jquery-ui
//= require blacklight/blacklight          
}          
        end
        directory("../../../../app/assets/images/blacklight", "public/images/blacklight")
      else
        # directories are relative to the source_root 
        directory("../../../../app/assets/images/blacklight", "public/images/blacklight")
        directory("../../../../app/assets/stylesheets", "public/stylesheets") 
        directory("../../../../app/assets/javascripts", "public/javascripts") 
      end
    end

    private
    def use_asset_pipeline?
      (Rails::VERSION::MAJOR >= 3 and Rails::VERSION::MINOR >= 1) and Rails.application.config.assets.enabled
    end
    
  end
end
