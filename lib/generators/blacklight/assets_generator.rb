# -*- encoding : utf-8 -*-
# Copy Blacklight assets to public folder in current app. 
# If you want to do this on application startup, you can
# add this next line to your one of your environment files --
# generally you'd only want to do this in 'development', and can
# add it to environments/development.rb:
#       require File.join(Blacklight.root, "lib", "generators", "blacklight", "assets_generator.rb")
#       Blacklight::AssetsGenerator.start(["--force", "--quiet"])


# Need the requires here so we can call the generator from environment.rb
# as suggested above. 
require 'rails/generators'
require 'rails/generators/base'
module Blacklight
  class Assets < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
  
    def assets
      directory("public/images")
      directory("public/stylesheets") 
      directory("public/javascripts") 
    end
    
  end
end
