# frozen_string_literal: true

module Blacklight
  class Component < ViewComponent::Base
    class << self
      alias upstream_sidecar_files sidecar_files

      def reset_compiler!
        @__vc_compiler = nil
      end

      # This allows the host application to provide erb templates that override the templates
      # provided by Blacklight.
      def sidecar_files(*args, **kwargs)
        upstream_sidecar_files(*args, **kwargs).map do |path|
          components_path = ViewComponent::VERSION::MAJOR == 3 ? view_component_path : config.generate.path

          app_path = Rails.root.join(path.slice(path.index(components_path)..-1).to_s).to_s

          if File.exist?(app_path)
            app_path
          else
            path
          end
        end
      end
    end
  end
end
