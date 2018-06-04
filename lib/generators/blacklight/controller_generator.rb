# frozen_string_literal: true
module Blacklight
  class ControllerGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    argument :controller_name, type: :string, default: "catalog"

    desc <<-EOS
      This generator makes the following changes to your application:
       1. Injects behavior into your user application_controller.rb
       2. Creates a Blacklight::Catalog-based controller
       3. Adds routes for your controller
    EOS

    # Add Blacklight to the application controller
    def inject_blacklight_controller_behavior
      inject_into_class "app/controllers/application_controller.rb", "ApplicationController" do
        "  # Adds a few additional behaviors into the application controller\n" \
        "  include Blacklight::Controller\n" \
        "  layout :determine_layout if respond_to? :layout\n\n"
      end
    end

    # Generate blacklight catalog controller
    def create_blacklight_catalog
      template "catalog_controller.rb", "app/controllers/#{controller_name}_controller.rb"
    end

    def inject_blacklight_routes
      route <<-EOF
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end
      EOF
    end
  end
end
