# frozen_string_literal: true

module Blacklight
  # This renders the partials for a single document on the search results view.
  # This differs from ShowDocumentPartialsRenderer, because it needs to handle
  # different view types like "list", "gallery", etc.
  #
  # This also has caching, because it might have to look up the same templates many times.
  class IndexDocumentPartialsRenderer < DocumentPartialsRenderer
    def initialize(presenter:, partials:, view:, view_cache:, view_type:)
      super(presenter: presenter, partials: partials, view: view)
      @view_cache = view_cache
      @view_type = view_type
    end

    private

    def find_template base_name, format, locals
      @view_cache.cached_view ['show', @view_type, base_name, format].join('_') do
        super
      end
    end

    # Used in #find_template
    def partial_name(str, base_name, format)
      format(str, action_name: base_name, format: format, index_view_type: @view_type)
    end

    ##
    # A list of document partial templates to try to render for a document
    #
    # The partial names will be interpolated with the following variables:
    #   - action_name: (e.g. index, show)
    #   - index_view_type: (the current view type, e.g. list, gallery)
    #   - format: the document's format (e.g. book)
    #
    # @see #render_document_partial
    def path_templates
      # first, the legacy template names for backwards compatbility
      # followed by the new, inheritable style
      # finally, a controller-specific path for non-catalog subclasses
      @path_templates ||= [
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
  end
end
