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
  def render_link_rel_alternates(document = @document, options = {})
    return if document.nil?
    presenter(document).link_rel_alternates(options)
  end

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
  # Determine whether to render a given field in the index view.
  #
  # @param [SolrDocument] document
  # @param [Blacklight::Configuration::Field] field_config
  # @return [Boolean]
  def should_render_index_field? document, field_config
    should_render_field?(field_config, document) && document_has_value?(document, field_config)
  end

  ##
  # Determine whether to render a given field in the show view
  #
  # @param [SolrDocument] document
  # @param [Blacklight::Configuration::Field] field_config
  # @return [Boolean]
  def should_render_show_field? document, field_config
    should_render_field?(field_config, document) && document_has_value?(document, field_config)
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
  # Render the index field label for a document
  #
  # Translations for index field labels should go under blacklight.search.fields
  # They are picked up from there by a value "%{label}" in blacklight.search.index.label
  #
  # @overload render_index_field_label(options)
  #   Use the default, document-agnostic configuration
  #   @param [Hash] opts
  #   @option opts [String] :field
  # @overload render_index_field_label(document, options)
  #   Allow an extention point where information in the document
  #   may drive the value of the field
  #   @param [SolrDocument] doc
  #   @param [Hash] opts
  #   @option opts [String] :field
  def render_index_field_label *args
    options = args.extract_options!
    document = args.first

    field = options[:field]
    html_escape t(:"blacklight.search.index.#{document_index_view_type}.label", default: :'blacklight.search.index.label', label: index_field_label(document, field))
  end

  ##
  # Render the show field label for a document
  #
  # @overload render_document_show_field_label(options)
  #   Use the default, document-agnostic configuration
  #   @param [Hash] opts
  #   @option opts [String] :field
  # @overload render_document_show_field_label(document, options)
  #   Allow an extention point where information in the document
  #   may drive the value of the field
  #   @param [SolrDocument] doc
  #   @param [Hash] opts
  #   @option opts [String] :field
  def render_document_show_field_label *args
    options = args.extract_options!
    document = args.first

    field = options[:field]

    t(:'blacklight.search.show.label', label: document_show_field_label(document, field))
  end

  ##
  # Get the value of the document's "title" field, or a placeholder
  # value (if empty)
  #
  # @param [SolrDocument] document
  # @return [String]
  def document_heading document = nil
    document ||= @document
    presenter(document).heading
  end

  ##
  # Get the document's "title" to display in the <title> element.
  # (by default, use the #document_heading)
  #
  # @see #document_heading
  # @param [SolrDocument] document
  # @return [String]
  def document_show_html_title document = nil
    document ||= @document

    presenter(document).html_title
  end

  ##
  # Render the document "heading" (title) in a content tag
  # @overload render_document_heading(document, options)
  #   @param [SolrDocument] document
  #   @param [Hash] options
  #   @option options [Symbol] :tag
  # @overload render_document_heading(options)
  #   @param [Hash] options
  #   @option options [Symbol] :tag
  def render_document_heading(*args)
    options = args.extract_options!
    document = args.first
    tag = options.fetch(:tag, :h4)
    document ||= @document

    content_tag(tag, presenter(document).heading, itemprop: "name")
  end

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

  ##
  # Returns a document presenter for the given document
  # TODO: Move this to the controller. It can just pass a presenter or set of presenters.
  def presenter(document)
    case action_name
    when 'show', 'citation'
      show_presenter(document)
    when 'index'
      index_presenter(document)
    end
  end

  def show_presenter(document)
    show_presenter_class(document).new(document, self)
  end

  def index_presenter(document)
    index_presenter_class(document).new(document, self)
  end

  ##
  # Override this method if you want to use a different presenter class
  def show_presenter_class(_document)
    blacklight_config.show.document_presenter_class
  end

  def index_presenter_class(_document)
    blacklight_config.index.document_presenter_class
  end

  def search_bar_presenter_class
    blacklight_config.index.search_bar_presenter_class
  end

  ##
  # Open Search discovery tag for HTML <head> links
  def opensearch_description_tag title, href
    tag :link, href: href, title: title, type: "application/opensearchdescription+xml", rel: "search"
  end
end
