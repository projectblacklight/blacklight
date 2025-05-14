# frozen_string_literal: true

module Blacklight
  module Facets
    # Standard display of a selected facet value (e.g. without a link and with a remove button)
    class SelectedValueComponent < Blacklight::Component
      def initialize(label:, href:)
        @label = label
        @href = href
        super
      end

      attr_reader :label, :href

      def call
        tag.span(class: "facet-label") do
          tag.span(label, class: "selected") + remove_link
        end
      end

      def remove_link
        link_to(href, class: "remove ps-2", rel: "nofollow") do
          render(Blacklight::Icons::RemoveComponent.new(aria_hidden: true)) +
            tag.span(t(:'blacklight.search.facets.selected.remove'), class: 'visually-hidden')
        end
      end
    end
  end
end
