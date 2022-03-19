# frozen_string_literal: true

# this approach has less API vulnerability but won't allow addition of sidecar files
module Blacklight
  class CompilerDemonstrationComponent < ::ViewComponent::Base
    class << self
      # rubocop:disable Naming/MemoizedInstanceVariableName
      def compiler
        @__vc_compiler ||= EngineCompiler.new(self)
      end
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end

    class EngineCompiler < ::ViewComponent::Compiler
      def templates
        @templates ||= begin
          extensions = ActionView::Template.template_handler_extensions

          component_class._sidecar_files(extensions).each_with_object([]) do |path, memo|
            pieces = File.basename(path).split(".")
            app_path = "#{Rails.root}/#{path.slice(path.index(@component_class.view_component_path)..-1)}"

            memo << {
              path: File.exist?(app_path) ? app_path : path,
              variant: pieces.second.split("+").second&.to_sym,
              handler: pieces.last
            }
          end
        end
      end
    end
  end
end
