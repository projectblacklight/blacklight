module Blacklight
  module DefaultComponentConfiguration
    extend ActiveSupport::Concern

    included do
      add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

      add_results_collection_tool(:sort_widget)
      add_results_collection_tool(:per_page_widget)
      add_results_collection_tool(:view_type_group)

      add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
      add_show_tools_partial(:refworks, if: :render_refworks_action?, modal: false)
      add_show_tools_partial(:endnote, if: :render_endnote_action?, modal: false, path: :single_endnote_catalog_path )
      add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
      add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
      add_show_tools_partial(:citation)
      add_show_tools_partial(:librarian_view, if: :render_librarian_view_control?)

      add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
      add_nav_action(:saved_searches, partial: 'blacklight/nav/saved_searches', if: :render_saved_searches?)
      add_nav_action(:search_history, partial: 'blacklight/nav/search_history')
    end

    module ClassMethods

      ##
      # Add a partial to the tools for rendering a document
      # @param partial [String] the name of the document partial
      # @param opts [Hash]
      # @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true.
      #                             The proc will receive the action configuration and the document or documents for the action.
      # @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true
      #                             The proc will receive the action configuration and the document or documents for the action.
      def add_show_tools_partial name, opts = {}
        blacklight_config.add_show_tools_partial(name, opts)

        define_method name do
          @response, @documents = action_documents

          if request.post? and
              opts[:callback] and
              (opts[:validator].blank? || self.send(opts[:validator]))

            self.send(opts[:callback], @documents)

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
        end unless method_defined? name
      end

      ##
      # Add a tool to be displayed for each document in the search results.
      # @param partial [String] the name of the document partial
      # @param opts [Hash]
      # @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true.
      #                             The proc will receive the action configuration and the document or documents for the action.
      # @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true
      #                             The proc will receive the action configuration and the document or documents for the action.
      def add_results_document_tool name, opts = {}
        blacklight_config.add_results_document_tool(name, opts)
      end

      ##
      # Add a tool to be displayed for the list of search results themselves.
      # @param partial [String] the name of the document partial
      # @param opts [Hash]
      # @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true.
      #                             The proc will receive the action configuration and the document or documents for the action.
      # @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true
      #                             The proc will receive the action configuration and the document or documents for the action.
      def add_results_collection_tool name, opts = {}
        blacklight_config.add_results_collection_tool(name, opts)
      end

      ##
      # Add a partial to the header navbar
      # @param partial [String] the name of the document partial
      # @param opts [Hash]
      # @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true.
      #                             The proc will receive the action configuration and the document or documents for the action.
      # @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true
      #                             The proc will receive the action configuration and the document or documents for the action.
      def add_nav_action name, opts = {}
        blacklight_config.add_nav_action(name, opts)
      end
    end
  end
end
