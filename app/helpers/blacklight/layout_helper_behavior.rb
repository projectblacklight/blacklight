# frozen_string_literal: true

# Methods added to this helper will be available to all templates in the hosting
# application
module Blacklight
  # A module for useful methods used in layout configuration
  module LayoutHelperBehavior
    ##
    # Classes added to a document's show content div
    # @return [String]
    def show_content_classes
      "#{main_content_classes} show-document"
    end

    ##
    # Attributes to add to the <html> tag (e.g. lang and dir)
    # @return [Hash]
    def html_tag_attributes
      { lang: I18n.locale }
    end

    ##
    # Classes added to a document's sidebar div
    # @return [String]
    def show_sidebar_classes
      sidebar_classes
    end

    ##
    # Classes used for sizing the main content of a Blacklight page
    # @return [String]
    def main_content_classes
      'col-lg-9'
    end

    ##
    # Classes used for sizing the sidebar content of a Blacklight page
    # @return [String]
    def sidebar_classes
      'page-sidebar col-lg-3'
    end

    ##
    # Class used for specifying main layout container classes.
    # Set config.full_width_layout to true to use a fluid layout.
    # @return [String]
    def container_classes
      blacklight_config.full_width_layout ? 'container-fluid' : 'container'
    end

    ##
    # Render "document actions" area for navigation header
    # (normally renders "Saved Searches", "History", "Bookmarks")
    # These things are added by add_nav_action
    #
    # @param [Hash] options
    # @return [String]
    def render_nav_actions(options = {}, &block)
      render_filtered_partials(blacklight_config.navbar.partials, options, &block)
    end

    ##
    # Open Search discovery tag for HTML <head> links
    # @return [String]
    def opensearch_description_tag title, href
      tag :link, href: href, title: title, type: "application/opensearchdescription+xml", rel: "search"
    end

    ##
    # Get the page's HTML title
    #
    # @return [String]
    def render_page_title
      (content_for(:page_title) if content_for?(:page_title)) || @page_title || application_name
    end

    ##
    # Create <link rel="alternate"> links from a documents dynamically
    # provided export formats.
    #
    # Returns empty string if no links available.
    #
    # @param [SolrDocument] document
    # @param [Hash] options
    # @option options [Boolean] :unique ensures only one link is output for every
    #     content type, e.g. as required by atom
    # @option options [Array<String>] :exclude array of format shortnames to not include in the output
    # @return [String]
    def render_link_rel_alternates(document = @document, options = {})
      return if document.nil?

      document_presenter(document).link_rel_alternates(options)
    end

    ##
    # Render classes for the <body> element
    # @return [String]
    def render_body_class
      extra_body_classes.join " "
    end

    ##
    # List of classes to be applied to the <body> element
    # @see render_body_class
    # @return [Array<String>]
    def extra_body_classes
      @extra_body_classes ||= ["blacklight-#{controller.controller_name}", "blacklight-#{[controller.controller_name, controller.action_name].join('-')}"]
    end
  end
end
