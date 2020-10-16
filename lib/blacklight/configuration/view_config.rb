# frozen_string_literal: true
class Blacklight::Configuration
  class ViewConfig < Blacklight::OpenStructWithHashAccess
    # @!attribute partials
    #   @return [Array<String>] partials to render for each document(see #render_document_partials)
    # @!attribute document_presenter_class
    #   @return [Class] document presenter class used by helpers and views
    # @!attribute document_component
    #   @return [Class] component class used to render a document; defaults to Blacklight::DocumentComponent
    # @!attribute title_field
    #   @return [String, Symbol] solr field to use to render a document title
    # @!attribute display_type_field
    #   @return [String, Symbol] solr field to use to render format-specific partials
    # @!attribute document_actions
    #   @return [NestedOpenStructWithHashAccess{Symbol => Blacklight::Configuration::ToolConfig}] 'tools' to render for each document
    def search_bar_presenter_class
      super || Blacklight::SearchBarPresenter
    end

    def display_label(key)
      I18n.t(
        :"blacklight.search.view_title.#{key}",
        default: [
          :"blacklight.search.view.#{key}",
          label,
          title,
          key.to_s.humanize
        ]
      )
    end

    class Show < ViewConfig
      # @!attribute route
      #   @return [Hash] Default route parameters for 'show' requests.
      #     Set this to a hash with additional arguments to merge into the route,
      #     or set `controller: :current` to route to the current controller.

      def document_presenter_class
        super || Blacklight::ShowPresenter
      end
    end

    class Index < ViewConfig
      # @!attribute group
      #   @return [false, String, Symbol] what field, if any, to use to render grouped results
      # @!attribute respond_to
      #   @return [OpenStructWithHashAccess{Symbol => OpenStruct}] additional response formats for search results;
      #      see Blacklight::Catalog#additional_response_formats for information about the OpenStruct data
      # @!attribute collection_actions
      #   @return [String, Symbol]

      def document_presenter_class
        super || Blacklight::IndexPresenter
      end
    end
  end
end
