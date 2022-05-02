# frozen_string_literal: true

# Methods added to this helper will be available to all templates in the hosting application
module Blacklight::BlacklightHelperBehavior
  include Blacklight::UrlHelperBehavior
  include Blacklight::LayoutHelperBehavior
  include Blacklight::IconHelperBehavior

  # @!group Layout helpers

  ##
  # Get the name of this application from an i18n string
  # key: blacklight.application_name
  # Try first in the current locale, then the default locale
  #
  # @return [String] the application name
  def application_name
    # It's important that we don't use ActionView::Helpers::CacheHelper#cache here
    # because it returns nil.
    Rails.cache.fetch 'blacklight/application_name' do
      t('blacklight.application_name',
        default: t('blacklight.application_name', locale: I18n.default_locale))
    end
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

  ##
  # Render the search navbar
  # @return [String]
  def render_search_bar
    search_bar_presenter.render
  end

  # @!group Presenter extension helpers
  ##
  # @return [Blacklight::SearchBarPresenter]
  def search_bar_presenter
    @search_bar ||= search_bar_presenter_class.new(controller, blacklight_config)
  end

  ##
  # Get the current "view type" (and ensure it is a valid type)
  #
  # @param [Hash] query_params the query parameters to check
  # @return [Symbol]
  def document_index_view_type query_params = params
    view_param = query_params[:view]
    view_param ||= session[:preferred_view]
    if view_param && document_index_views.key?(view_param.to_sym)
      view_param.to_sym
    else
      default_document_index_view_type
    end
  end

  # @!group Search result helpers
  ##
  # Render a partial of an arbitrary format inside a
  # template of a different format. (e.g. render an HTML
  # partial from an XML template)
  # code taken from:
  # http://stackoverflow.com/questions/339130/how-do-i-render-a-partial-of-a-different-format-in-rails (zgchurch)
  #
  # @param [String] format suffix
  # @yield
  def with_format(format)
    old_formats = formats
    self.formats = [format]
    yield
    self.formats = old_formats
    nil
  end

  ##
  # Should we render a grouped response (because the response
  # contains a grouped response instead of the normal response)
  #
  # Default to false if there's no response object available (sometimes the case
  #   for tests, but might happen in other circumstances too..)
  # @return [Boolean]
  def render_grouped_response? response = @response
    response&.grouped?
  end

  ##
  # Returns a document presenter for the given document
  def document_presenter(document, counter: nil)
    document_presenter_class(document).new(document, self, counter: counter)
  end

  ##
  # Override this method if you want to use a differnet presenter for your documents
  # @param [Blacklight::Document] _document optional, here for extension + backwards compatibility only
  def document_presenter_class(_document = nil)
    case action_name
    when 'show', 'citation'
      blacklight_config.view_config(:show, action_name: action_name).document_presenter_class
    else
      blacklight_config.view_config(document_index_view_type, action_name: action_name).document_presenter_class
    end
  end

  # @return [Class]
  def search_bar_presenter_class
    blacklight_config.view_config(action_name: :index).search_bar_presenter_class
  end

  # @!group Layout helpers
  ##
  # Open Search discovery tag for HTML <head> links
  # @return [String]
  def opensearch_description_tag title, href
    tag :link, href: href, title: title, type: "application/opensearchdescription+xml", rel: "search"
  end
end
