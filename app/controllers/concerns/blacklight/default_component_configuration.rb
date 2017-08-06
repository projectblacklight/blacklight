# frozen_string_literal: true
module Blacklight
  module DefaultComponentConfiguration
    extend ActiveSupport::Concern

    included do
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

    def render_sms_action?(_config, _options)
      sms_mappings.present?
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

        return if method_defined?(name) || opts[:define_method] == false

        # Define a simple action handler for the tool
        define_method name do
          @response, @documents = action_documents

          if request.post? && opts[:callback] &&
            (opts[:validator].blank? || send(opts[:validator]))

            send(opts[:callback], @documents)

            flash[:success] ||= I18n.t("blacklight.#{name}.success", default: nil)

            respond_to do |format|
              format.html { redirect_to action_success_redirect_path }
              format.js { render "#{name}_success" }
            end
          else
            respond_to do |format|
              format.html
              format.js { render :layout => false }
            end
          end
        end
      end
      # rubocop:enable Metrics/LineLength

      # Add a tool to be displayed for each document in the search results.
      # @!macro partial_if_unless
      def add_results_document_tool(name, opts = {})
        blacklight_config.add_results_document_tool(name, opts)
      end

      # Add a tool to be displayed for the list of search results themselves.
      # @!macro partial_if_unless
      def add_results_collection_tool(name, opts = {})
        blacklight_config.add_results_collection_tool(name, opts)
      end

      # Add a partial to the header navbar.
      # @!macro partial_if_unless
      def add_nav_action(name, opts = {})
        blacklight_config.add_nav_action(name, opts)
      end
    end
  end
end
