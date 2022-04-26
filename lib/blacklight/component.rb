# frozen_string_literal: true

module Blacklight
  class Component < ViewComponent::Base
    class << self
      # rubocop:disable Naming/MemoizedInstanceVariableName
      def compiler
        @__vc_compiler ||= EngineCompiler.new(self)
      end
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end

    class EngineCompiler < ::ViewComponent::Compiler
      # ViewComponent::Compiler locates and caches templates from sidecar files to the component source file.
      # While this is sensible in a Rails application, it prevents component templates defined in an Engine
      # from being overridden by an installing application without subclassing the component, which may also
      # require modifying any partials rendering the component. This subclass of compiler overrides the template
      # location algorithm to take the sidecar file names from the Engine, but look to see if a file of the
      # same name existing in the installing application (ie, under Rails.root). If the latter exists, this
      # compiler will cache that template instead of the engine-defined file; if not, the compiler will fall
      # back to the engine-defined file.
      def templates
        @templates ||= begin
          extensions = ActionView::Template.template_handler_extensions

          component_class._sidecar_files(extensions).each_with_object([]) do |path, memo|
            pieces = File.basename(path).split(".")
            app_path = "#{Rails.root}/#{path.slice(path.index(component_class.view_component_path)..-1)}"

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
