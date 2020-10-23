# frozen_string_literal: true
module Blacklight
  class IndexPresenter < DocumentPresenter
    ##
    # Render the document index heading. This is used when making a link to a
    # document, where we don't want any HTML markup added from the pipeline.
    #
    # @param [Symbol, Proc, String] field_or_string_or_proc Render the given field or evaluate the proc or render the given string
    # @param [Hash] opts
    def label(field_or_string_or_proc, opts = {})
      config = Configuration::NullField.new
      value = case field_or_string_or_proc
                when Symbol
                  config = field_config(field_or_string_or_proc)
                  field_presenter(config).values
                when Proc
                  Deprecation.warn(self, "calling IndexPresenter.label with a Proc is deprecated. " \
                                         "First argument must be a symbol. This will be removed in Blacklight 8")
                  field_or_string_or_proc.call(document, opts)
                when String
                  Deprecation.warn(self, "calling IndexPresenter.label with a String is deprecated. " \
                                         "First argument must be a symbol. This will be removed in Blacklight 8")
                  field_or_string_or_proc
              end

      value = document.id if value.blank?
      field_value(config, values: Array.wrap(value), except_operations: [Rendering::HelperMethod])
    end

    deprecation_deprecate label: 'Use #heading'

    def view_config
      @view_config ||= configuration.view_config(view_context.document_index_view_type)
    end

    private

    # @return [Hash<String,Configuration::Field>] all the fields for this index view
    def fields
      configuration.index_fields_for(display_type)
    end

    def field_config(field)
      configuration.index_fields.fetch(field) { Configuration::NullField.new(field) }
    end
  end
end
