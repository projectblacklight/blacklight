# frozen_string_literal: true

module Blacklight
  module Document
    ##
    # Render a legacy document partial (e.g. one configured with `config.index.partials`) for a document.
    #
    # The partial is chosen based on the base name, the current index view type, and the document's
    # display type (see {Blacklight::DocumentPresenter#display_type}). If no partial matching the
    # display type is found, the default partial for the base name is rendered.
    #
    # To customize the partial lookup, subclass this component and configure it with
    # `config.index.document_partial_component = MyPartialComponent`.
    #
    # @see #path_templates
    class PartialComponent < Blacklight::Component
      # @param document [Blacklight::Document]
      # @param base_name [String, Symbol] base name for the partial (e.g. 'show', 'index_header')
      # @param presenter [Blacklight::DocumentPresenter, nil] presenter for the document; defaults to
      #   the presenter returned by the `document_presenter` helper
      # @param view_type [String, Symbol, nil] the index view type (e.g. 'list', 'gallery'); defaults
      #   to the current view type
      # @param locals [Hash] local variables to pass through to the partial
      def initialize(document:, base_name:, presenter: nil, view_type: nil, locals: {})
        @document = document
        @base_name = base_name
        @presenter = presenter
        @view_type = view_type
        @locals = locals
      end

      def call
        if template
          # Builder (XML) templates return a plain string; template output is already escaped as appropriate.
          template.render(helpers, @locals.merge(document: @document)).to_s.html_safe # rubocop:disable Rails/OutputSafety
        else
          logger&.warn("No template was found for base_name: '#{@base_name}', view_type: '#{view_type}' in #{self.class.name}")
          ''
        end
      end

      # @return [String] the normalized partial name for the document's display type
      def partial_name
        return legacy_helper_call(:document_partial_name, @document, @base_name) if legacy_helper_override?(:document_partial_name)

        display_type = presenter.display_type(@base_name, default: 'default')

        return legacy_helper_call(:type_field_to_partial_name, @document, display_type) if legacy_helper_override?(:type_field_to_partial_name)

        type_field_to_partial_name(display_type)
      end

      ##
      # A list of document partial templates to try to render for a document
      #
      # The partial names will be interpolated with the following variables:
      #   - action_name: the base name of the partial (e.g. index, show)
      #   - index_view_type: (the current view type, e.g. list, gallery)
      #   - format: the document's display type (e.g. book)
      #
      # @return [Array<String>]
      def path_templates
        return legacy_helper_call(:document_partial_path_templates) if legacy_helper_override?(:document_partial_path_templates)

        [
          "%{action_name}_%{index_view_type}_%{format}",
          "%{action_name}_%{index_view_type}_default",
          "%{action_name}_%{format}",
          "%{action_name}_default",
          "%{action_name}",
          "catalog/%{action_name}_%{format}",
          "catalog/_%{action_name}_partials/%{format}",
          "catalog/_%{action_name}_partials/default"
        ]
      end

      private

      def presenter
        @presenter ||= helpers.document_presenter(@document)
      end

      def view_type
        @view_type ||= helpers.document_index_view_type
      end

      def logger
        helpers.logger
      end

      ##
      # Transform a display type into a partial name (e.g. 'PdfBook' => 'pdf_book')
      #
      # @param display_type [String, Array] a value suggestive of a partial
      # @return [String] the name of the partial to render
      def type_field_to_partial_name(display_type)
        # using "_" as sep. to more closely follow the views file naming conventions
        # parameterize uses "-" as the default sep. which throws errors
        underscore = '_'
        Array(display_type).join(' ').tr('-', underscore).parameterize(separator: underscore)
      end

      def template
        return @template if defined?(@template)

        @template = find_template
      end

      def find_template
        name = partial_name
        lookup_context = helpers.lookup_context

        path_templates.each do |str|
          partial = format(str, action_name: @base_name, format: name, index_view_type: view_type)
          logger&.debug "Looking for document partial #{partial}"
          template = lookup_context.find_all(partial, lookup_context.prefixes + [""], true, @locals.keys + [:document], {}).first
          return template if template
        end

        nil
      end

      def legacy_helper_override?(method_name)
        return false unless helpers.respond_to?(method_name, true)

        helpers.method(method_name).owner != Blacklight::RenderPartialsHelperBehavior
      end

      def legacy_helper_call(method_name, *)
        Blacklight.deprecation.warn("Overriding the ##{method_name} helper is deprecated. " \
                                    "Subclass #{Blacklight::Document::PartialComponent} and configure it with " \
                                    "`config.index.document_partial_component` instead.")
        helpers.send(method_name, *)
      end
    end
  end
end
