# frozen_string_literal: true

module Blacklight
  class Component < ViewComponent::Base
    class << self
      alias upstream_sidecar_files sidecar_files

      SIDECAR_ROOTS = ['app/components', 'app/views/components'].freeze

      def reset_compiler!
        @__vc_compiler = nil
      end

      def sidecar_files(*args, **kwargs)
        upstream_sidecar_files(*args, **kwargs).map do |path|
          app_path = app_sidecar_path(path)

          if app_path && File.exist?(app_path)
            app_path
          else
            path
          end
        end
      end

      private

      def app_sidecar_path(path)
        relative_path = SIDECAR_ROOTS.lazy.filter_map do |root|
          path.to_s[%r{(?:^|/)(#{Regexp.escape(root)}/.*)\z}, 1]
        end.first

        Rails.root.join(relative_path).to_s if relative_path
      end
    end
  end
end
