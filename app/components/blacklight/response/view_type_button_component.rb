# frozen_string_literal: true

module Blacklight
  module Response
    # Render spellcheck results for a search query
    class ViewTypeButtonComponent < ViewComponent::Base
      with_collection_parameter :view
      # @param [Blacklight::Configuration::View] view
      def initialize(view:, key: nil, selected: false, search_state: nil, classes: 'btn btn-outline-secondary btn-icon')
        @view = view
        @key = key || view.key
        @selected = selected
        @classes = classes
        @search_state = search_state
      end

      def icon
        Deprecation.silence(Blacklight::CatalogHelperBehavior) do
          @view_context.render_view_type_group_icon(@view.icon || @key)
        end
      end

      def label
        @view.display_label(@key)
      end

      def url
        @view_context.url_for(@search_state.to_h.merge(view: @key))
      end

      def selected?
        @selected
      end
    end
  end
end
