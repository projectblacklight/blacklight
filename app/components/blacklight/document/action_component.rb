# frozen_string_literal: true

module Blacklight
  module Document
    # Render a bookmark widget to bookmark / unbookmark a document
    class ActionComponent < Blacklight::Component
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

      def render_control
        return link_to_modal_control if using_default_document_action?

        render_partial
      end

      def using_default_document_action?
        @action.component || @action.partial == 'document_action'
      end

      def link_to_modal_control
        link_to label,
                url,
                id: @id,
                class: @link_classes,
                data: {}.merge(({ blacklight_modal: "trigger", turbo: false } if @action.modal != false) || {})
      end

      def render_partial
        render(partial: @action.partial || @action.name.to_s,
               locals: { document: @document, document_action_config: @action }.merge(@options))
      end

      def label
        t("blacklight.tools.#{@action.name}", default: @action.label || @action.name.to_s.humanize)
      end

      # Action buttons get their URLs in one of three ways:
      # - the action configuration explicitly specifies a helper method to call
      # - a url route is inferred for ActiveModel-compliant objects (the default;
      #     note that, although Rails routing is available here, we still call out to
      #     helpers regardless, because that's where applications might have overridden the
      #     default Rails routing behavior)
      # - calling out to an implicit helper method with a conventional name (unlikely)
      def url
        url_opts = @url_opts.merge(({ id: @document } if @document) || {})
        if @action.path
          helpers.public_send(@action.path, url_opts)
        elsif url_opts[:id].class.respond_to?(:model_name)
          helpers.url_for([@action.key.to_sym, url_opts[:id]])
        else
          helpers.public_send("#{@action.key}_#{helpers.controller_name}_path", url_opts)
        end
      end

      def key
        @action.key
      end
    end
  end
end
