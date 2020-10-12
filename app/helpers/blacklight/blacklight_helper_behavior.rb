# frozen_string_literal: true
# Methods added to this helper will be available to all templates in the hosting application
module Blacklight::BlacklightHelperBehavior
  extend Deprecation

  include Blacklight::UrlHelperBehavior
  include Blacklight::HashAsHiddenFieldsHelperBehavior
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
  # Render OpenSearch headers for this search
  # @deprecated
  # @return [String]
  def render_opensearch_response_metadata
    render partial: 'catalog/opensearch_response_metadata', locals: { response: @response }
  end
  deprecation_deprecate render_opensearch_response_metadata: 'Use `render "catalog/opensearch_response_metadata"\' instead'

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

  # @!group Presenter extension helpers
  ##
  # @return [Blacklight::SearchBarPresenter]
  def search_bar_presenter
    @search_bar ||= search_bar_presenter_class.new(controller, blacklight_config)
  end

  # @!group Document helpers
  ##
  # Determine whether to render a given field in the index view.
  #
  # @deprecated
  # @param [SolrDocument] document
  # @param [Blacklight::Configuration::Field] field_config
  # @return [Boolean]
  def should_render_index_field? document, field_config
    Deprecation.warn self, "should_render_index_field? is deprecated and will be removed in Blacklight 8. Use IndexPresenter#render_field? instead."
    should_render_field?(field_config, document) && document_has_value?(document, field_config)
  end

  ##
  # Determine whether to render a given field in the show view
  #
  # @deprecated
  # @param [SolrDocument] document
  # @param [Blacklight::Configuration::Field] field_config
  # @return [Boolean]
  def should_render_show_field? document, field_config
    Deprecation.warn self, "should_render_show_field? is deprecated and will be removed in Blacklight 8. Use ShowPresenter#render_field? instead."
    should_render_field?(field_config, document) && document_has_value?(document, field_config)
  end

  ##
  # Check if a document has (or, might have, in the case of accessor methods) a value for
  # the given solr
  # @deprecated
  # @param [SolrDocument] document
  # @param [Blacklight::Configuration::Field] field_config
  # @return [Boolean]
  def document_has_value? document, field_config
    Deprecation.warn self, "document_has_value? is deprecated and will be removed in Blacklight 8. Use DocumentPresenter#has_value? instead."
    document.has?(field_config.field) ||
      (document.has_highlight_field? field_config.field if field_config.highlight) ||
      field_config.accessor
  end

  # @!group Search result helpers
  ##
  # Determine whether to display spellcheck suggestions
  #
  # @deprecated
  # @param [Blacklight::Solr::Response] response
  # @return [Boolean]
  def should_show_spellcheck_suggestions? response
    Deprecation.silence(Blacklight::ConfigurationHelperBehavior) do
      # The spelling response field may be missing from non solr repositories.
      response.total <= spell_check_max &&
        !response.spelling.nil? &&
        response.spelling.words.any?
    end
  end
  deprecation_deprecate should_show_spellcheck_suggestions?: 'moving into a private method of Blacklight::Response::SpellcheckComponent'

  # @!group Document helpers
  ##
  # Render the index field label for a document
  #
  # Translations for index field labels should go under blacklight.search.fields
  # They are picked up from there by a value "%{label}" in blacklight.search.index.label
  #
  # @deprecated
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
  # @return [String]
  def render_index_field_label *args
    options = args.extract_options!
    document = args.first

    field = options[:field]
    label = Deprecation.silence(Blacklight::ConfigurationHelperBehavior) do
      options[:label] || index_field_label(document, field)
    end
    html_escape t(:"blacklight.search.index.#{document_index_view_type}.label", default: :'blacklight.search.index.label', label: label)
  end
  deprecation_deprecate render_index_field_label: 'Use Blacklight::MetadataFieldComponent instead'

  ##
  # Render the show field label for a document
  #
  # @deprecated
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
  # @return [String]
  def render_document_show_field_label *args
    options = args.extract_options!
    document = args.first

    field = options[:field]
    label = Deprecation.silence(Blacklight::ConfigurationHelperBehavior) do
      options[:label] || document_show_field_label(document, field)
    end

    t(:'blacklight.search.show.label', label: label)
  end
  deprecation_deprecate render_document_show_field_label: 'Use Blacklight::MetadataFieldComponent instead'

  ##
  # Get the value of the document's "title" field, or a placeholder
  # value (if empty)
  #
  # @deprecated
  # @param [SolrDocument] document
  # @return [String]
  def document_heading document = nil
    document ||= @document
    document_presenter(document).heading
  end
  deprecation_deprecate document_heading: 'Use Blacklight::DocumentPresenter#heading instead'

  ##
  # Get the document's "title" to display in the <title> element.
  # (by default, use the #document_heading)
  #
  # @deprecated
  # @see #document_heading
  # @param [SolrDocument] document
  # @return [String]
  def document_show_html_title document = nil
    document ||= @document

    document_presenter(document).html_title
  end
  deprecation_deprecate document_show_html_title: 'Use Blacklight::DocumentPresenter#html_title instead'

  ##
  # Render the document "heading" (title) in a content tag
  # @deprecated
  # @overload render_document_heading(document, options)
  #   @param [SolrDocument] document
  #   @param [Hash] options
  #   @option options [Symbol] :tag
  # @overload render_document_heading(options)
  #   @param [Hash] options
  #   @option options [Symbol] :tag
  # @return [String]
  def render_document_heading(*args)
    options = args.extract_options!
    document = args.first
    tag = options.fetch(:tag, :h4)
    document ||= @document

    content_tag(tag, document_presenter(document).heading, itemprop: "name")
  end
  deprecation_deprecate render_document_heading: 'Removed without replacement'

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

  # @!group Presenter extension helpers
  ##
  # Returns a document presenter for the given document
  # TODO: Move this to the controller. It can just pass a presenter or set of presenters.
  # @deprecated
  # @return [Blacklight::DocumentPresenter]
  def presenter(document)
    Deprecation.warn(Blacklight::BlacklightHelperBehavior, '#presenter is deprecated; use #document_presenter instead')

    # As long as the presenter methods haven't been overridden, we can use the new behavior
    if method(:show_presenter).owner == Blacklight::BlacklightHelperBehavior &&
       method(:index_presenter).owner == Blacklight::BlacklightHelperBehavior
      return document_presenter_class(document).new(document, self)
    end

    Deprecation.warn(Blacklight::BlacklightHelperBehavior, '#show_presenter and/or #index_presenter have been overridden; please override #document_presenter instead')

    Deprecation.silence(Blacklight::BlacklightHelperBehavior) do
      case action_name
      when 'show', 'citation'
        show_presenter(document)
      else
        index_presenter(document)
      end
    end
  end

  ##
  # Returns a document presenter for the given document
  def document_presenter(document)
    Deprecation.silence(Blacklight::BlacklightHelperBehavior) do
      presenter(document)
    end
  end

  # @deprecated
  # @return [Blacklight::ShowPresenter]
  def show_presenter(document)
    Deprecation.warn(Blacklight::BlacklightHelperBehavior, '#show_presenter is deprecated; use #document_presenter instead')

    if method(:show_presenter_class).owner != Blacklight::BlacklightHelperBehavior
      Deprecation.warn(Blacklight::BlacklightHelperBehavior, '#show_presenter_class has been overridden; please override #document_presenter_class instead')
    end

    Deprecation.silence(Blacklight::BlacklightHelperBehavior) do
      show_presenter_class(document).new(document, self)
    end
  end

  # @deprecated
  # @return [Blacklight::IndexPresenter]
  def index_presenter(document)
    Deprecation.warn(Blacklight::BlacklightHelperBehavior, '#index_presenter is deprecated; use #document_presenter instead')

    if method(:index_presenter_class).owner != Blacklight::BlacklightHelperBehavior
      Deprecation.warn(Blacklight::BlacklightHelperBehavior, '#index_presenter_class has been overridden; please override #document_presenter_class instead')
    end

    Deprecation.silence(Blacklight::BlacklightHelperBehavior) do
      index_presenter_class(document).new(document, self)
    end
  end

  ##
  # Override this method if you want to use a differnet presenter for your documents
  def document_presenter_class(document)
    Deprecation.silence(Blacklight::BlacklightHelperBehavior) do
      case action_name
      when 'show', 'citation'
        show_presenter_class(document)
      else
        index_presenter_class(document)
      end
    end
  end

  ##
  # Override this method if you want to use a different presenter class
  # @deprecated
  # @return [Class]
  def show_presenter_class(_document)
    Deprecation.warn(Blacklight::BlacklightHelperBehavior, '#show_presenter_class is deprecated; use #document_presenter_class instead')

    blacklight_config.show.document_presenter_class
  end

  # @deprecated
  # @return [Class]
  def index_presenter_class(_document)
    Deprecation.warn(Blacklight::BlacklightHelperBehavior, '#index_presenter_class is deprecated; use #document_presenter_class instead')

    (blacklight_config.view.key?(document_index_view_type) && blacklight_config.dig(:view, document_index_view_type, :document_presenter_class)) ||
      blacklight_config.index.document_presenter_class
  end

  # @return [Class]
  def search_bar_presenter_class
    blacklight_config.index.search_bar_presenter_class
  end

  # @!group Layout helpers
  ##
  # Open Search discovery tag for HTML <head> links
  # @return [String]
  def opensearch_description_tag title, href
    tag :link, href: href, title: title, type: "application/opensearchdescription+xml", rel: "search"
  end

  # @private

  def self.blacklight_path
    @blacklight_path ||= Gem.loaded_specs["blacklight"].full_gem_path
  end

  def partial_from_blacklight?(partial)
    path = lookup_context.find_all(partial, lookup_context.prefixes + [""], true).first&.identifier

    path&.starts_with?(Blacklight::BlacklightHelperBehavior.blacklight_path)
  end
end
