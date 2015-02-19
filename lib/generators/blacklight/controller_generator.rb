module Blacklight
  class ControllerGenerator < Rails::Generators::Base
    
    source_root File.expand_path('../templates', __FILE__)
    
    argument     :controller_name  , type: :string , default: "catalog"

    desc """
  This generator makes the following changes to your application:
   1. Injects behavior into your user application_controller.rb
   2. Creates a Blacklight::Catalog-based controller
   3. Adds routes for your controller

  Thank you for Installing Blacklight.
         """

    # Add Blacklight to the application controller
    def inject_blacklight_controller_behavior
      inject_into_class "app/controllers/application_controller.rb", "ApplicationController" do
        "  # Adds a few additional behaviors into the application controller \n" +
        "  include Blacklight::Controller\n" +
        "  layout 'blacklight'\n\n"
      end
    end
    
    # Generate blacklight catalog controller
    def create_blacklight_catalog
      template "catalog_controller.rb", "app/controllers/#{controller_name}_controller.rb"
    end

    def inject_blacklight_routes
      # These will end up in routes.rb file in reverse order
      # we add em, since each is added at the top of file. 
      # we want "root" to be FIRST for optimal url generation. 
      route("blacklight_for :#{controller_name}")
    end
  end
end
