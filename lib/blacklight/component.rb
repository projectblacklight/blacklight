# frozen_string_literal: true

module Blacklight
  class Component < ViewComponent::Base
    class << self
      alias upstream_sidecar_files sidecar_files

      def reset_compiler!
        @__vc_compiler = nil
      end

      def sidecar_files(*args, **kwargs)
        upstream_sidecar_files(*args, **kwargs).map do |path|
          app_path = Rails.root.join(path.slice(path.index(view_component_path)..-1).to_s).to_s

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
