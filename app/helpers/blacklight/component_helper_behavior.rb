# frozen_string_literal: true

module Blacklight
  module ComponentHelperBehavior
    ##
    # Render "document actions" area for search results view
    # (normally renders next to title in the list view)
    #
    # @param [SolrDocument] document
    # @param [String] wrapping_class ("index-document-functions")
    # @param [Class] component (Blacklight::Document::ActionsComponent)
    # @return [String]
    def render_index_doc_actions(document, wrapping_class: "index-document-functions", component: Blacklight::Document::ActionsComponent)
      actions = filter_partials(blacklight_config.view_config(document_index_view_type).document_actions, { document: document }).map { |_k, v| v }

      render(component.new(document: document, actions: actions, classes: wrapping_class))
    end

    ##
    # Render "collection actions" area for search results view
    # (normally renders next to pagination at the top of the result set)
    #
    # @param [String] wrapping_class ("search-widgets")
    # @param [Class] component (Blacklight::Document::ActionsComponent)
    # @return [String]
    def render_results_collection_tools(wrapping_class: "search-widgets", component: Blacklight::Document::ActionsComponent)
      actions = filter_partials(blacklight_config.view_config(document_index_view_type).collection_actions, {}).map { |_k, v| v }

      render(component.new(actions: actions, classes: wrapping_class))
    end

    def show_doc_actions?(document = @document, options = {})
      filter_partials(blacklight_config.view_config(:show).document_actions, { document: document }.merge(options)).any?
    end

    def document_actions(document, options: {})
      filter_partials(blacklight_config.view_config(:show).document_actions, { document: document }.merge(options)).map { |_k, v| v }
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
