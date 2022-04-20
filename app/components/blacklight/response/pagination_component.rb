# frozen_string_literal: true

module Blacklight
  module Response
    # Render a pagination widget for search results
    class PaginationComponent < Blacklight::Component
      # @param [Blacklight::Response] response
      # @param [Hash] html html options for the pagination container
      def initialize(response:, html: {}, **pagination_args)
        @response = response
        @html_attr = { aria: { label: t('views.pagination.aria.container_label') } }.merge(html)
        @pagination_args = pagination_args
      end

      def pagination
        helpers.paginate @response, **Blacklight::Engine.config.blacklight.default_pagination_options, **@pagination_args
      end
    end
  end
end
