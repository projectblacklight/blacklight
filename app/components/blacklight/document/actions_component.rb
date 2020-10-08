# frozen_string_literal: true

module Blacklight
  module Document
    # Render a bookmark widget to bookmark / unbookmark a document
    class ActionsComponent < ::ViewComponent::Base
      # @param [Blacklight::Document] document
      def initialize(document: nil, actions: [], options: {}, url_opts: nil, classes: 'index-document-functions', block: nil)
        @document = document
        @actions = actions
        @classes = classes
        @options = options
        @block = block
        @url_opts = url_opts
      end

      def render?
        @actions.any?
      end
    end
  end
end
