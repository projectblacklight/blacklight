# frozen_string_literal: true

module Blacklight
  class AssetsGenerator < Rails::Generators::Base
    class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 5.1'), desc: "Set the generated app's bootstrap version"

    def run_asset_pipeline_specific_generator
      generated_options = "--bootstrap-version='#{options[:'bootstrap-version']}'" if options[:'bootstrap-version']

      generator = if defined?(Propshaft)
                    'blacklight:assets:propshaft'
                  elsif defined?(Importmap)
                    'blacklight:assets:importmap'
                  elsif defined?(Sprockets)
                    'blacklight:assets:sprockets'
                  end

      generate generator, generated_options if generator
    end
  end
end
