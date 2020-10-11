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
        t(@action.name, context: 'blacklight.tools', default: @action.label || @action.name.to_s.humanize)
      end

      def url
        if @action.path
          send(@action.path, url_opts)
        elsif @document&.class&.respond_to?(:model_name)
          url_for([@action.key, url_opts[:id]])
        else
          send("#{@action.key}_#{@view_context.controller_name}_path", url_opts)
        end
      end
    end
  end
end
