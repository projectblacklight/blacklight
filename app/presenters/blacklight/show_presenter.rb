# frozen_string_literal: true
module Blacklight
  class ShowPresenter < DocumentPresenter
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
