# frozen_string_literal: true

require 'shellwords'

module Blacklight
  class AssetsGenerator < Rails::Generators::Base
    class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 4.0'), desc: "Set the generated app's bootstrap version"

    def run_asset_pipeline_specific_generator
      generated_options = "--bootstrap-version='#{Shellwords.escape(options[:'bootstrap-version'])}'" if options[:'bootstrap-version']

      # Blacklight 7.x JS is distributed via Sprockets (//= require directives, jQuery, etc.)
      # so we always use the sprockets generator regardless of what Rails defaulted to.
      generate 'blacklight:assets:sprockets', generated_options
    end
  end
end
