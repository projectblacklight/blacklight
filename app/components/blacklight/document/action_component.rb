# frozen_string_literal: true

module Blacklight
  module Document
    # Render a bookmark widget to bookmark / unbookmark a document
    class ActionComponent < ::ViewComponent::Base
      with_collection_parameter :action

      # @param [Blacklight::Document] document
      def initialize(document:, action:, options: {}, url_opts: {}, id: nil)
        @document = document
        @action = action
        @options = options
        @url_opts = url_opts
        @id = id || @action.fetch(:id, "#{@action.name}Link")
      end

      def using_default_document_action?
        return true if @action.component
        return false unless @action.partial == 'document_action'

        @view_context.partial_from_blacklight?(@action.partial)
      end

      def label
        Deprecation.silence(Blacklight::ComponentHelperBehavior) do
          @view_context.document_action_label(@action.name, @action)
        end
      end

      def url
        Deprecation.silence(Blacklight::ComponentHelperBehavior) do
          @view_context.document_action_path(@action, @url_opts.merge(({ id: @document } if @document) || {}))
        end
      end
    end
  end
end
