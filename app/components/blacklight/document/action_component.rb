# frozen_string_literal: true

module Blacklight
  module Document
    # Render a bookmark widget to bookmark / unbookmark a document
    class ActionComponent < ::ViewComponent::Base
      with_collection_parameter :action

      # @param [Blacklight::Document] document
      def initialize(document:, action:, options: {}, url_opts: {}, id: nil, link_classes: 'nav-link')
        @document = document
        @action = action
        @options = options
        @url_opts = url_opts
        @id = id || @action.fetch(:id, "#{@action.name}Link")
        @link_classes = link_classes
      end

      def using_default_document_action?
        return true if @action.component
        return false unless @action.partial == 'document_action'

        helpers.partial_from_blacklight?(@action.partial)
      end

      def label
        Deprecation.silence(Blacklight::ComponentHelperBehavior) do
          helpers.document_action_label(@action.name, @action)
        end
      end

      # Action buttons get their URLs in one of three ways:
      # - the action configuration explicitly specifies a helper method to call
      # - a url route is inferred for ActiveModel-compliant objects (the default;
      #     note that, although Rails routing is available here, we still call out to
      #     helpers regardless, because that's where applications might have overridden the
      #     default Rails routing behavior)
      # - calling out to an implicit helper method with a conventional name (unlikely)
      def url
        Deprecation.silence(Blacklight::ComponentHelperBehavior) do
          helpers.document_action_path(@action, @url_opts.merge(({ id: @document } if @document) || {}))
        end
      end

      def key
        @action.key
      end
    end
  end
end
