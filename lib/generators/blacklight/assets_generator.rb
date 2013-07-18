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
        insert_into_file "app/assets/javascripts/application.js", :after => "//= require jquery_ujs" do
  %q{
//= require jquery-1.9.1.js
//= require jquery-ui.min.js
//
// Required by Blacklight
//= require blacklight/blacklight
//
// Require for Autocomplete
//= require solr-config.js
//= require ./solr-autocomplete/ajax-solr/core/Core.js
//= require ./solr-autocomplete/ajax-solr/core/AbstractManager.js
//= require ./solr-autocomplete/ajax-solr/managers/Manager.jquery.js
//= require ./solr-autocomplete/ajax-solr/core/Parameter.js
//= require ./solr-autocomplete/ajax-solr/core/ParameterStore.js
//= require ./solr-autocomplete/ajax-solr/core/AbstractWidget.js
//= require ./solr-autocomplete/ajax-solr/core/AbstractTextWidget.js
//= require ./solr-autocomplete/ajax-solr/widgets/AutocompleteWidget.js}  
        
        end
      end

      directory("../../../../app/assets/images/blacklight", "app/assets/images/blacklight")
    end
  end
end
