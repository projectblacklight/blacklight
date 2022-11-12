# frozen_string_literal: true

module Blacklight
  module Assets
    class PropshaftGenerator < Rails::Generators::Base
      def add_package
        run 'yarn add blacklight-frontend'
      end

      def add_package_assets
        append_to_file 'app/assets/stylesheets/application.bootstrap.scss' do
          <<~CONTENT
            @import "blacklight-frontend/app/assets/stylesheets/blacklight/blacklight";
          CONTENT
        end

        append_to_file 'app/javascript/application.js' do
          <<~CONTENT
            import "blacklight-frontend/app/assets/javascripts/blacklight/index";
          CONTENT
        end
      end
    end
  end
end
