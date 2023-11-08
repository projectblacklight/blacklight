# frozen_string_literal: true

module Blacklight
  module Response
    # Render a pagination widget for search results
    class PaginationComponent < Blacklight::Component
      # @param [Blacklight::Response] response
      # @param [Hash] html html options for the pagination container
      def initialize(response:, html: {}, **pagination_args)
        @response = response
        @html = html
        @pagination_args = pagination_args
      end

      def html_attr
        { aria: { label: t('views.pagination.aria.container_label') } }.merge(@html)
      end

      def pagination
        args = configured_options.merge(@pagination_args).compact
        helpers.paginate @response, **args
      end

      def configured_options
        controller.blacklight_config.index.pagination_options
      end
    end
  end
end
