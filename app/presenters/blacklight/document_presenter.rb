# frozen_string_literal: true

module Blacklight
  # An abstract class that the view presenters for SolrDocuments descend from
  class DocumentPresenter
    attr_reader :document, :configuration, :view_context

    # @return [Hash<String,Configuration::Field>]  all the fields for this index view that should be rendered
    def fields_to_render
      fields.select do |_name, field_config|
        # rubocop:disable Style/PreferredHashMethods
        render_field?(field_config) && has_value?(field_config)
        # rubocop:enable Style/PreferredHashMethods
      end
    end

    private

    ##
    # Check to see if the given field should be rendered in this context
    # @param [Blacklight::Configuration::Field] field_config
    # @return [Boolean]
    def render_field?(field_config)
      view_context.should_render_field?(field_config, document)
    end

    ##
    # Check if a document has (or, might have, in the case of accessor methods) a value for
    # the given solr field
    # @param [Blacklight::Configuration::Field] field_config
    # @return [Boolean]
    def has_value? field_config
      document.has?(field_config.field) ||
        (document.has_highlight_field? field_config.field if field_config.highlight) ||
        field_config.accessor
    end
  end
end
