# frozen_string_literal: true

module Blacklight
  module Document
    # Render a bookmark widget to bookmark / unbookmark a document
    class ActionsComponent < ::ViewComponent::Base
      # @param [Blacklight::Document] document
      # rubocop:disable Metrics/ParameterLists
      def initialize(document: nil, actions: [], options: {}, url_opts: nil, tag: :div, classes: 'index-document-functions', wrapping_tag: nil, wrapping_classes: nil)
        @document = document
        @actions = actions
        @tag = tag
        @classes = classes
        @options = options
        @url_opts = url_opts
        @wrapping_tag = wrapping_tag
        @wrapping_classes = wrapping_classes
      end
      # rubocop:enable Metrics/ParameterLists

      def render?
        @actions.any?
      end
    end
  end
end
