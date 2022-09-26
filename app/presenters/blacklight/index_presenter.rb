# frozen_string_literal: true

module Blacklight
  class IndexPresenter < DocumentPresenter
    def view_config
      configuration.view_config(view_context.document_index_view_type)
    end

    private

    # @return [Hash<String,Configuration::Field>] all the fields for this index view
    def fields
      configuration.index_fields_for(display_type)
    end

    def field_config(field)
      configuration.index_fields.fetch(field) { Configuration::NullDisplayField.new(field) }
    end
  end
end
