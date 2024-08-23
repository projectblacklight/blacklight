# frozen_string_literal: true

module Blacklight
  class MetadataFieldComponent < Blacklight::Component
    with_collection_parameter :field

    # @param field [Blacklight::FieldPresenter]
    # @param layout [Blacklight::MetadataFieldLayoutComponent] alternate layout component to use
    # @param show [Boolean] are we showing only a single document (vs a list of search results); used for backwards-compatibility
    def initialize(field:, layout: nil, show: false, view_type: nil)
      @field = field
      @layout = layout || Blacklight::MetadataFieldLayoutComponent
      @view_type = view_type
      @show = show
    end

    def label
      if @show
        show_field_label @field.label('show')
      else
        index_field_label @field.label
      end
    end

    def render?
      @field.render_field?
    end

    # Override this method in a subclass to change the way this value is rendered
    def render_field
      @field.render
    end

    ##
    # Render the index field label for a document
    #
    # Translations for index field labels should go under blacklight.search.fields
    # They are picked up from there by a value "%{label}" in blacklight.search.index.label
    # @return [String]
    def index_field_label label
      html_escape t(:"blacklight.search.index.#{@view_type}.label", default: :'blacklight.search.index.label', label: label)
    end

    ##
    # Render the show field label for a document
    #
    # @return [String]
    def show_field_label label
      t(:'blacklight.search.show.label', label: label)
    end
  end
end
