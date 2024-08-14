# frozen_string_literal: true

module Blacklight
  module Document
    # Render the start over and prev/next displays
    class PageHeaderComponent < Blacklight::Component
      attr_reader :document, :blacklight_config, :search_context, :search_session

      delegate :blacklight_config, to: :helpers

      def initialize(document:, search_context:, search_session:)
        super
        @search_context = search_context
        @search_session = search_session
        @document = document
      end

      def render?
        search_context.present? || search_session.present? || has_header_tools?
      end

      def applied_params_component
        return unless blacklight_config.track_search_session.applied_params_component

        blacklight_config.track_search_session.applied_params_component.new
      end

      def pagination_component
        return unless blacklight_config.track_search_session.item_pagination_component

        blacklight_config.track_search_session.item_pagination_component.new(search_context: search_context, search_session: search_session, current_document: document)
      end

      def has_header_tools?
        header_actions.any? || show_header_tools_component
      end

      def pagination_container_classes
        has_header_tools? ? 'col-12 col-md-6 ms-auto' : ''
      end

      def header_container_classes
        has_header_tools? ? 'row pagination-search-widgets pb-2' : 'pagination-search-widgets'
      end

      def header_actions
        actions = helpers.filter_partials(blacklight_config.view_config(:show).header_actions, { document: document })
        actions.map { |_k, v| v }
      end

      def show_header_tools_component
        blacklight_config.view_config(:show).show_header_tools_component
      end

      def default_action_component_render
        render Blacklight::Document::ActionsComponent.new(document: document,
                                                          tag: action_component_tag,
                                                          classes: classes,
                                                          link_classes: link_classes,
                                                          actions: header_actions,
                                                          url_opts: Blacklight::Parameters.sanitize(params.to_unsafe_h))
      end

      def action_component_tag
        'div'
      end

      def classes
        'd-inline-flex header-tools align-items-center col-12 col-md-6 ms-auto justify-content-md-end'
      end

      def link_classes
        'btn btn-outline-primary ms-2'
      end

      def render_header_tools
        return unless has_header_tools?

        return render show_header_tools_component.new(document: document) if show_header_tools_component

        default_action_component_render
      end
    end
  end
end
