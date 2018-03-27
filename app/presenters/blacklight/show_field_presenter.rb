# frozen_string_literal: true

module Blacklight
  class ShowFieldPresenter
    # @param show_presenter [ShowPresenter]
    # @param field [Configuration::Field]
    def initialize(show_presenter, field)
      @show_presenter = show_presenter
      @field = field
    end

    attr_reader :field, :document, :show_presenter
    delegate :view_type, :document, to: :index_presenter

    def to_param
      field.key.parameterize
    end

    ##
    # Render the show field label for a document
    #
    # @param [Blacklight::Configuration::Field] field
    def label
      I18n.t(:'blacklight.search.show.label',
             label: field.show_field_label)
    end

    ##
    # Get the value for a document's field, and prepare to render it.
    # - highlight_field
    # - accessor
    # - solr field
    #
    # Rendering:
    #   - helper_method
    #   - link_to_facet
    # @param [Blacklight::Configuration::Field] field solr field configuration
    # @param [Hash] options additional options to pass to the rendering helpers
    def value(options = {})
      FieldPresenter.new(show_presenter.view_context,
                         show_presenter.document,
                         field,
                         options).render
    end
  end
end
