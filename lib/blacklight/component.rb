# frozen_string_literal: true

module Blacklight
  class Component < ViewComponent::Base
    class << self
      # Workaround for https://github.com/ViewComponent/view_component/issues/1565
      def config
        @config ||= ViewComponent::Config.defaults.merge(ViewComponent::Base.config)
      end

      # rubocop:disable Naming/MemoizedInstanceVariableName
      def compiler
        @__vc_compiler ||= EngineCompiler.new(self)
      end
      # rubocop:enable Naming/MemoizedInstanceVariableName

      alias sidecar_files _sidecar_files unless ViewComponent::Base.respond_to? :sidecar_files
    end

    EXCLUDE_VARIABLES = [
      :@lookup_context, :@view_renderer, :@view_flow, :@view_context,
      :@tag_builder, :@current_template,
      :@__vc_set_slots, :@__vc_original_view_context,
      :@__vc_variant, :@__vc_content_evaluated,
      :@__vc_render_in_block, :@__vc_content, :@__vc_helpers
    ].freeze

    def inspect
      # Exclude variables added by render_in
      render_variables = instance_variables - EXCLUDE_VARIABLES
      fields = render_variables.map { |ivar| "#{ivar}:#{instance_variable_get(ivar).inspect}" }.join(', ')
      "#<#{self.class.name}:#{object_id} #{fields}>"
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

          component_class.sidecar_files(extensions).each_with_object([]) do |path, memo|
            pieces = File.basename(path).split(".")
            app_path = Rails.root.join(path.slice(path.index(component_class.view_component_path)..-1).to_s).to_s

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
