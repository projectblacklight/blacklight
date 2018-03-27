# frozen_string_literal: true
# Methods added to this helper will be available to all templates in the hosting application
module Blacklight::BlacklightHelperBehavior
  include UrlHelperBehavior
  include HashAsHiddenFieldsHelperBehavior
  include LayoutHelperBehavior
  include IconHelperBehavior

  ##
  # Get the name of this application from an i18n string
  # key: blacklight.application_name
  #
  # @return [String] the application name
  def application_name
    t('blacklight.application_name')
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
  # @param [#link_rel_alternates] presenter
  # @param [Hash] options
  # @option options [Boolean] :unique ensures only one link is output for every
  #     content type, e.g. as required by atom
  # @option options [Array<String>] :exclude array of format shortnames to not include in the output
  def render_link_rel_alternates(presenter = @presenter, options = {})
    presenter.link_rel_alternates(options)
  end
  deprecation_deprecate render_link_rel_alternates: 'use ShowPresenter#link_rel_alternates instead'

  ##
  # Render OpenSearch headers for this search
  # @return [String]
  def render_opensearch_response_metadata
    render partial: 'catalog/opensearch_response_metadata'
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
    @extra_body_classes ||= ['blacklight-' + controller.controller_name, 'blacklight-' + [controller.controller_name, controller.action_name].join('-')]
  end

  ##
  # Render the search navbar
  # @return [String]
  def render_search_bar
    search_bar_presenter.render
  end

  def search_bar_presenter
    @search_bar ||= search_bar_presenter_class.new(controller, blacklight_config)
  end

  ##
  # Check if a document has (or, might have, in the case of accessor methods) a value for
  # the given solr field
  # @param [SolrDocument] document
  # @param [Blacklight::Configuration::Field] field_config
  # @return [Boolean]
  def document_has_value? document, field_config
    document.has?(field_config.field) ||
      (document.has_highlight_field? field_config.field if field_config.highlight) ||
      field_config.accessor
  end

  ##
  # Determine whether to display spellcheck suggestions
  #
  # @param [Blacklight::Solr::Response] response
  # @return [Boolean]
  def should_show_spellcheck_suggestions? response
    response.total <= spell_check_max && response.spelling.words.any?
  end

  ##
  # Get the value of the document's "title" field, or a placeholder
  # value (if empty)
  #
  # @param [#heading] document
  # @return [String]
  def document_heading presenter = nil
    presenter ||= @presenter
    presenter.heading
  end

  ##
  # Get the document's "title" to display in the <title> element.
  # (by default, use the #document_heading)
  #
  # @see #document_heading
  # @return [String]
  def document_show_html_title
    @presenter.html_title
  end
  deprecation_deprecate document_show_html_title: 'use ShowPresenter#html_title instead'

  ##
  # Render the document "heading" (title) in a content tag
  # @overload render_document_heading(presenter, options)
  #   @param [#heading] presenter
  #   @param [Hash] options
  #   @option options [Symbol] :tag
  # @overload render_document_heading(options)
  #   @param [Hash] options
  #   @option options [Symbol] :tag
  def render_document_heading(*args)
    options = args.extract_options!
    presenter = args.first
    tag = options.fetch(:tag, :h4)
    presenter ||= @presenter

    content_tag(tag, presenter.heading, itemprop: "name")
  end
  deprecation_deprecate render_document_heading: 'use ShowPresenter#render_document_heading'

  ##
  # Get the current "view type" (and ensure it is a valid type)
  #
  # @param [Hash] query_params the query parameters to check
  # @return [Symbol]
  def document_index_view_type query_params = params
    view_param = query_params[:view]
    view_param ||= session[:preferred_view]
    if view_param && document_index_views.keys.include?(view_param.to_sym)
      view_param.to_sym
    else
      default_document_index_view_type
    end
  end

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
  def render_grouped_response? response = @response
    response.grouped?
  end

  # TODO: move this into the ResultsPagePresenter & ShowPagePresenter?
  def search_bar_presenter_class
    blacklight_config.index.search_bar_presenter_class
  end

  ##
  # Open Search discovery tag for HTML <head> links
  def opensearch_description_tag title, href
    tag :link, href: href, title: title, type: "application/opensearchdescription+xml", rel: "search"
  end
end
