# frozen_string_literal: true

module Blacklight
  class IndexFieldPresenter
    # @param index_presenter [IndexPresenter]
    # @param field [Configuration::IndexField]
    def initialize(index_presenter, field)
      @index_presenter = index_presenter
      @field = field
    end

    attr_reader :field, :document, :index_presenter
    delegate :view_type, :document, to: :index_presenter

    def to_param
      field.key.parameterize
    end

    ##
    # Render the index field label for a document
    #
    # Translations for index field labels should go under blacklight.search.fields
    # They are picked up from there by a value "%{label}" in blacklight.search.index.label
    def label
      I18n.t(:"blacklight.search.index.#{view_type}.label",
             default: :'blacklight.search.index.label',
             label: field.index_field_label)
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
    # @param [Blacklight::Configuration::Field] field_config solr field configuration
    # @param [Hash] options additional options to pass to the rendering helpers
    def value(options = {})
      FieldPresenter.new(index_presenter.view_context,
                         index_presenter.document,
                         field,
                         options).render
    end
  end
end
