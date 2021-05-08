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
        @action.component || @action.partial == 'document_action'
      end

      def label
        t("blacklight.tools.#{@action.name}", default: @action.label || @action.name.to_s.humanize)
      end

      def url
        url_opts = @url_opts.merge(({ id: @document } if @document) || {})
        if @action.path
          public_send(@action.path, url_opts)
        elsif url_opts[:id].class.respond_to?(:model_name)
          url_for([@action.key, url_opts[:id]])
        else
          public_send("#{@action.key}_#{controller_name}_path", url_opts)
        end
      end

      def key
        @action.key
      end
    end
  end
end
