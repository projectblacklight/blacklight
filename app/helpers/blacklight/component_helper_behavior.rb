# frozen_string_literal: true
module Blacklight
  module ComponentHelperBehavior
    def document_action_label action, opts
      t("blacklight.tools.#{action}", default: opts.label || action.to_s.humanize)
    end

    def document_action_path action_opts, url_opts = nil
      if action_opts.path
        send(action_opts.path, url_opts)
      elsif url_opts[:id].class.respond_to?(:model_name)
        url_for([action_opts.key, url_opts[:id]])
      else
        send("#{action_opts.key}_#{controller_name}_path", url_opts)
      end
    end

    ##
    # Render "document actions" area for navigation header
    # (normally renders "Saved Searches", "History", "Bookmarks")
    #
    # @param [Hash] options
    # @return [String]
    def render_nav_actions(options = {}, &block)
      render_filtered_partials(blacklight_config.navbar.partials, options, &block)
    end

    ##
    # Render "document actions" area for search results view
    # (normally renders next to title in the list view)
    #
    # @param [SolrDocument] document
    # @param [Hash] options
    # @option options [String] :wrapping_class
    # @return [String]
    def render_index_doc_actions(document, options = {})
      wrapping_class = options.delete(:wrapping_class) || "index-document-functions"
      rendered = render_filtered_partials(blacklight_config.view_config(document_index_view_type).document_actions, { document: document }.merge(options))
      content_tag("div", rendered, class: wrapping_class) unless rendered.blank?
    end

    ##
    # Render "collection actions" area for search results view
    # (normally renders next to pagination at the top of the result set)
    #
    # @param [Hash] options
    # @option options [String] :wrapping_class
    # @return [String]
    def render_results_collection_tools(options = {})
      wrapping_class = options.delete(:wrapping_class) || "search-widgets"
      rendered = render_filtered_partials(blacklight_config.view_config(document_index_view_type).collection_actions, options)
      content_tag("div", rendered, class: wrapping_class) unless rendered.blank?
    end

    def render_filtered_partials(partials, options = {})
      content = []
      filter_partials(partials, options).each do |key, config|
        config.key ||= key
        rendered = render(partial: config.partial || key.to_s, locals: { document_action_config: config }.merge(options))
        if block_given?
          yield config, rendered
        else
          content << rendered
        end
      end
      safe_join(content, "\n") unless block_given?
    end

    ##
    # Render "document actions" for the item detail 'show' view.
    # (this normally renders next to title)
    #
    # By default includes 'Bookmarks'
    #
    # @param [SolrDocument] document
    # @param [Hash] options
    # @return [String]
    def render_show_doc_actions(document = @document, options = {}, &block)
      render_filtered_partials(blacklight_config.show.document_actions, { document: document }.merge(options), &block)
    end

    def show_doc_actions?(document = @document, options = {})
      filter_partials(blacklight_config.show.document_actions, { document: document }.merge(options)).any?
    end

    private

    def filter_partials(partials, options)
      partials.select { |_, config| blacklight_configuration_context.evaluate_if_unless_configuration config, options }
    end
  end
end
