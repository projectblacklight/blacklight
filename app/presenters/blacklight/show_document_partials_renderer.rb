# frozen_string_literal: true

module Blacklight
  class ShowDocumentPartialsRenderer < DocumentPartialsRenderer
    private

    ##
    # A list of document partial templates to try to render for a document
    #
    # The partial names will be interpolated with the following variables:
    #   - action_name: (e.g. index, show)
    #   - index_view_type: (the current view type, e.g. list, gallery)
    #   - format: the document's format (e.g. book)
    #
    # @see #render_document_partial
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
