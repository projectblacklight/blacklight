# frozen_string_literal: true

module Blacklight
  class AssetsGenerator < Rails::Generators::Base
    class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '5.3.5'), desc: "Set the generated app's bootstrap version"

    def run_asset_pipeline_specific_generator
      generated_options = "--bootstrap-version='#{options[:'bootstrap-version']}'" if options[:'bootstrap-version']

      generator = if defined?(Importmap)
                    'blacklight:assets:importmap'
                  elsif defined?(Propshaft)
                    'blacklight:assets:propshaft'
                  else
                    raise "Unsupported path"
                  end

      generate generator, generated_options if generator
    end
  end
end
