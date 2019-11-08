# frozen_string_literal: true
module Blacklight
  class ShowPresenter < DocumentPresenter
    ##
    # Create <link rel="alternate"> links from a documents dynamically
    # provided export formats. Returns empty string if no links available.
    #
    # @param [Hash] options
    # @option options [Boolean] :unique ensures only one link is output for every
    #     content type, e.g. as required by atom
    # @option options [Array<String>] :exclude array of format shortnames to not include in the output
    def link_rel_alternates(options = {})
      LinkAlternatePresenter.new(view_context, document, options).render
    end

    ##
    # Get the document's "title" to display in the <title> element.
    # (by default, use the #document_heading)
    #
    # @see #document_heading
    # @return [String]
    def html_title
      return field_values(view_config.html_title_field) if view_config.html_title_field.is_a? Blacklight::Configuration::Field

      if view_config.html_title_field
        fields = Array.wrap(view_config.html_title_field) + [configuration.document_model.unique_key]
        f = fields.lazy.map { |field| field_config(field) }.detect { |field_config| retrieve_values(field_config).any? }
        field_values(f)
      else
        heading
      end
    end

    private

    # @return [Hash<String,Configuration::Field>]
    def fields
      configuration.show_fields_for(display_type)
    end

    def view_config
      configuration.view_config(:show)
    end

    def field_config(field)
      configuration.show_fields.fetch(field) { Configuration::NullField.new(field) }
    end
  end
end
