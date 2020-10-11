# frozen_string_literal: true
module Blacklight
  module ComponentHelperBehavior
    extend Deprecation

    # @deprecated
    def document_action_label action, opts
      t("blacklight.tools.#{action}", default: opts.label || action.to_s.humanize)
    end
    deprecation_deprecate :document_action_label

    # @deprecated
    def document_action_path action_opts, url_opts = nil
      if action_opts.path
        send(action_opts.path, url_opts)
      elsif url_opts[:id].class.respond_to?(:model_name)
        url_for([action_opts.key, url_opts[:id]])
      else
        send("#{action_opts.key}_#{controller_name}_path", url_opts)
      end
    end
    deprecation_deprecate :document_action_path

    ##
    # Render "document actions" area for navigation header
    # (normally renders "Saved Searches", "History", "Bookmarks")
    # These things are added by add_nav_action and the default config is
    # provided by DefaultComponentConfiguration
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
      actions = filter_partials(blacklight_config.view_config(document_index_view_type).document_actions, { document: document }.merge(options)).map { |_k, v| v }
      wrapping_class = options.delete(:wrapping_class) || "index-document-functions"

      render(Blacklight::Document::ActionsComponent.new(document: document, actions: actions, options: options, classes: wrapping_class))
    end

    ##
    # Render "collection actions" area for search results view
    # (normally renders next to pagination at the top of the result set)
    #
    # @param [Hash] options
    # @option options [String] :wrapping_class
    # @return [String]
    def render_results_collection_tools(options = {})
      actions = filter_partials(blacklight_config.view_config(document_index_view_type).collection_actions, options).map { |_k, v| v }
      wrapping_class = options.delete(:wrapping_class) || "search-widgets"

      render(Blacklight::Document::ActionsComponent.new(actions: actions, options: options, classes: wrapping_class))
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
    def render_show_doc_actions(document = @document, url_opts: {}, **options)
      document = options[:document] if options.key? :document

      actions = document_actions(document, options: options)

      if block_given?
        # TODO: Deprecate this behavior and replace it with a separate component?
        # Deprecation.warn(Blacklight::ComponentHelperBehavior, 'Pass a block to #render_show_doc_actions is deprecated')
        actions.each do |action|
          yield action, render((action.component || Blacklight::Document::ActionComponent).new(action: action, document: document, options: options, url_opts: url_opts))
        end

        nil
      else
        render(Blacklight::Document::ActionsComponent.new(document: document, actions: actions, options: options, url_opts: url_opts))
      end
    end

    def render_show_doc_actions_method_from_blacklight?
      method(:render_show_doc_actions).owner == Blacklight::ComponentHelperBehavior
    end

    def show_doc_actions?(document = @document, options = {})
      filter_partials(blacklight_config.show.document_actions, { document: document }.merge(options)).any?
    end

    def document_actions(document, options: {})
      filter_partials(blacklight_config.show.document_actions, { document: document }.merge(options)).map { |_k, v| v }
    end

    private

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

    def filter_partials(partials, options)
      partials.select { |_, config| blacklight_configuration_context.evaluate_if_unless_configuration config, options }
    end
  end
end
