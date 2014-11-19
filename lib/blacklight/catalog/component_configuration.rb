module Blacklight
  module Catalog::ComponentConfiguration
    extend ActiveSupport::Concern
    include Blacklight::Catalog::DocumentActions

    included do
      # provided by Blacklight::Catalog::DocumentActions
      add_document_action(:bookmark, partial: 'catalog/bookmark_control', if: :render_bookmarks_control?)
      add_document_action(:refworks, if: Proc.new { |_, config, options|
        options[:document] && options[:document].respond_to?(:export_formats) && options[:document].export_formats.keys.include?( :refworks_marc_txt )} )
      add_document_action(:endnote, if: Proc.new { |_, config, options| options[:document] && options[:document].respond_to?(:export_formats) && options[:document].export_formats.keys.include?( :endnote )} )
      add_document_action(:email, callback: :email_action, validator: :validate_email_params)
      add_document_action(:sms, callback: :sms_action, validator: :validate_sms_params)
      add_document_action(:citation)
      add_document_action(:librarian_view, if: Proc.new { |ctx, config, options| ctx.respond_to? :librarian_view_catalog_path and options[:document] && options[:document].respond_to?(:to_marc) })

      add_index_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

      add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
      add_nav_action(:saved_searches, partial: 'blacklight/nav/saved_searches', if: :render_saved_searches?)
      add_nav_action(:search_history, partial: 'blacklight/nav/search_history')
    end

    module ClassMethods

      ##
      # Add a partial to the tools for each document in the search results.
      # @param partial [String] the name of the document partial
      # @param opts [Hash]
      # @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true.
      #                             The proc will receive the action configuration and the document or documents for the action.
      # @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true
      #                             The proc will receive the action configuration and the document or documents for the action.
      def add_index_tools_partial name, opts = {}
        blacklight_config.add_index_tools_partial(name, opts)
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
