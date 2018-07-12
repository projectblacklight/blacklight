# frozen_string_literal: true
module Blacklight
  module DefaultComponentConfiguration
    extend ActiveSupport::Concern

    included do
      Deprecation.warn(self, "Blacklight::DefaultComponentConfiguration is deprecated and will be removed in the next release." \
                             "this means you must call add_results_document_tool, add_results_collection_tool, " \
                             "add_show_tools_partial and add_nav_action manually in your config")
      add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

      add_results_collection_tool(:sort_widget)
      add_results_collection_tool(:per_page_widget)
      add_results_collection_tool(:view_type_group)

      add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
      add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
      add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
      add_show_tools_partial(:citation)

      add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
      add_nav_action(:search_history, partial: 'blacklight/nav/search_history')
    end

    module ClassMethods
      # YARD will include inline disabling as docs, cannot do multiline inside @!macro.  AND this must be separate from doc block.
      # rubocop:disable Metrics/LineLength

      # @!macro partial_if_unless
      #   @param name [String] the name of the document partial
      #   @param opts [Hash]
      #   @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true. The proc will receive the action configuration and the document or documents for the action.
      #   @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true. The proc will receive the action configuration and the document or documents for the action.

      # Add a partial to the tools for rendering a document
      # @!macro partial_if_unless
      # @option opts [Boolean] :define_method define a controller method as named, default: true
      # @option opts [Symbol]  :validator method for toggling between success and failure, should return Boolean (true if valid)
      # @option opts [Symbol]  :callback method for further processing of documents, receives Array of documents
      def add_show_tools_partial(name, opts = {})
        blacklight_config.add_show_tools_partial(name, opts)
        ActionBuilder.new(self, name, opts).build
      end
      # rubocop:enable Metrics/LineLength

      deprecation_deprecate add_show_tools_partial: 'use blacklight_config.add_show_tools_partial instead'

      # Add a tool to be displayed for each document in the search results.
      # @!macro partial_if_unless
      delegate :add_results_document_tool, to: :blacklight_config
      deprecation_deprecate add_results_document_tool: 'use blacklight_config.add_results_document_tool instead'

      # Add a tool to be displayed for the list of search results themselves.
      # @!macro partial_if_unless
      delegate :add_results_collection_tool, to: :blacklight_config
      deprecation_deprecate add_results_collection_tool: 'use blacklight_config.add_results_collection_tool instead'

      # Add a partial to the header navbar.
      # @!macro partial_if_unless
      delegate :add_nav_action, to: :blacklight_config
      deprecation_deprecate add_nav_action: 'use blacklight_config.add_nav_action instead'
    end
  end
end
