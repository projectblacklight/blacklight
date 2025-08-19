# frozen_string_literal: true

class Blacklight::Configuration
  class ViewConfig < Blacklight::OpenStructWithHashAccess
    # @!attribute template
    #   @return [String] partial to render around the documents
    # @!attribute document_presenter_class
    #   @return [Class] document presenter class used by helpers and views
    # @!attribute document_component
    #   @return [Class] component class used to render a document; defaults to Blacklight::DocumentComponent
    # @!attribute document_title_component
    #   @return [Class] component class used to render a document title
    # @!attribute document_metadata_component
    #   @return [Class] component class used to render the document metadata
    # @!attribute document_thumbnail_component
    #   @return [Class] component class used to render a document thumbnail
    # @!attribute document_embed_component
    #   @return [Class] component class used to render a document embed
    # @!attribute title_field
    #   @return [String, Symbol] solr field to use to render a document title
    # @!attribute display_type_field
    #   @return [String, Symbol] solr field to use to render format-specific partials
    # @!attribute icon
    #   @return [String, Symbol, Blacklight::Icons::IconComponent] icon file to use in the view picker
    # @!attribute document_actions
    #   @return [NestedOpenStructWithHashAccess{Symbol => Blacklight::Configuration::ToolConfig}] 'tools' to render for each document
    # @!attribute facet_group_component
    #   @return [Class] component class used to render a facet group
    # @!attribute constraints_component
    #   @return [Class] component class used to render the constraints
    # @!attribute search_bar_component
    #   @return [Class] component class used to render the search bar
    # @!attribute search_header_component
    #   @return [Class] component class used to render the header above the documents
    def display_label(**)
      I18n.t(
        :"blacklight.search.view_title.#{key}",
        default: [
          :"blacklight.search.view.#{key}",
          label,
          title,
          key.to_s.humanize
        ],
        **
      )
    end

    # Translate an ordinary field into the expected DisplayField object
    def title_field=(value)
      if value.is_a?(Blacklight::Configuration::Field) && !value.is_a?(Blacklight::Configuration::DisplayField)
        super(Blacklight::Configuration::DisplayField.new(value.to_h))
      else
        super
      end
    end

    # Provide backwards compatibility with the configuration keys without the document_ prefix
    def title_component(*) = document_title_component(*)
    def metadata_component(*) = document_metadata_component(*)
    def thumbnail_component(*) = document_thumbnail_component(*)
    def embed_component(*) = document_embed_component(*)

    def title_component=(value)
      self.document_title_component = value
    end

    def metadata_component=(value)
      self.document_metadata_component = value
    end

    def thumbnail_component=(value)
      self.document_thumbnail_component = value
    end

    def embed_component=(value)
      self.document_embed_component = value
    end

    class Show < ViewConfig
      # @!attribute route
      #   @return [Hash] Default route parameters for 'show' requests.
      #     Set this to a hash with additional arguments to merge into the route,
      #     or set `controller: :current` to route to the current controller.

      def document_presenter_class
        super || Blacklight::ShowPresenter
      end

      def to_h
        super.merge(document_presenter_class: document_presenter_class)
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

      def to_h
        super.merge(document_presenter_class: document_presenter_class)
      end
    end
  end
end
