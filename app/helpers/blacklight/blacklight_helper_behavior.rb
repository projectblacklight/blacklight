# -*- encoding : utf-8 -*-
# -*- coding: utf-8 -*-
#
# Methods added to this helper will be available to all templates in the hosting application
#
module Blacklight::BlacklightHelperBehavior
  include BlacklightUrlHelper
  include BlacklightConfigurationHelper
  include HashAsHiddenFieldsHelper
  include RenderConstraintsHelper
  include RenderPartialsHelper
  include FacetsHelper

  ##
  # Get the name of this application, from either:
  #  - the Rails configuration
  #  - an i18n string (key: blacklight.application_name; preferred)
  #
  # @return [String] the application name
  def application_name
    return Rails.application.config.application_name if Rails.application.config.respond_to? :application_name

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
  # @params [SolrDocument] document
  # @params [Hash] options
  # @option options [Boolean] :unique ensures only one link is output for every
  #     content type, e.g. as required by atom
  # @option options [Array<String>] :exclude array of format shortnames to not include in the output
  def render_link_rel_alternates(document=@document, options = {})
    return if document.nil?
    presenter(document).link_rel_alternates(options)
  end

  ##
  # Render OpenSearch headers for this search
  # @return [String]
  def render_opensearch_response_metadata
    render :partial => 'catalog/opensearch_response_metadata'
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
    render :partial=>'catalog/search_form'
  end

  ##
  # Determine whether to render a given field in the index view.
  #
  # @param [SolrDocument] document
  # @param [Blacklight::Solr::Configuration::Field] field_config
  # @return [Boolean]
  def should_render_index_field? document, field_config
    should_render_field?(field_config, document) && document_has_value?(document, field_config)
  end

  ##
  # Determine whether to render a given field in the show view
  #
  # @param [SolrDocument] document
  # @param [Blacklight::Solr::Configuration::Field] field_config
  # @return [Boolean]
  def should_render_show_field? document, field_config
    should_render_field?(field_config, document) && document_has_value?(document, field_config)
  end

  ##
  # Check if a document has (or, might have, in the case of accessor methods) a value for
  # the given solr field
  # @param [SolrDocument] document
  # @param [Blacklight::Solr::Configuration::Field] field_config
  # @return [Boolean]
  def document_has_value? document, field_config
    document.has?(field_config.field) ||
      (document.has_highlight_field? field_config.field if field_config.highlight) ||
      field_config.accessor
  end

  ##
  # Determine whether to display spellcheck suggestions
  #
  # @param [Blacklight::SolrResponse] response
  # @return [Boolean]
  def should_show_spellcheck_suggestions? response
    response.total <= spell_check_max and response.spelling.words.size > 0
  end

  ##
  # Render the index field label for a document
  #
  # @overload render_index_field_label(options)
  #   Use the default, document-agnostic configuration
  #   @param [Hash] opts
  #   @options opts [String] :field
  # @overload render_index_field_label(document, options)
  #   Allow an extention point where information in the document
  #   may drive the value of the field
  #   @param [SolrDocument] doc
  #   @param [Hash] opts
  #   @options opts [String] :field
  def render_index_field_label *args
    options = args.extract_options!
    document = args.first

    field = options[:field]
    html_escape t(:"blacklight.search.index.#{document_index_view_type}.label", default: :'blacklight.search.index.label', label: index_field_label(document, field))
  end

  ##
  # Render the index field label for a document
  #
  # @overload render_index_field_value(options)
  #   Use the default, document-agnostic configuration
  #   @param [Hash] opts
  #   @options opts [String] :field
  #   @options opts [String] :value
  #   @options opts [String] :document
  # @overload render_index_field_value(document, options)
  #   Allow an extention point where information in the document
  #   may drive the value of the field
  #   @param [SolrDocument] doc
  #   @param [Hash] opts
  #   @options opts [String] :field
  #   @options opts [String] :value
  # @overload render_index_field_value(document, field, options)
  #   Allow an extention point where information in the document
  #   may drive the value of the field
  #   @param [SolrDocument] doc
  #   @param [String] field
  #   @param [Hash] opts
  #   @options opts [String] :value
  def render_index_field_value *args
    options = args.extract_options!
    document = args.shift || options[:document]

    field = args.shift || options[:field]
    presenter(document).render_index_field_value field, options.except(:document, :field)
  end

  ##
  # Render the show field label for a document
  #
  # @overload render_document_show_field_label(options)
  #   Use the default, document-agnostic configuration
  #   @param [Hash] opts
  #   @options opts [String] :field
  # @overload render_document_show_field_label(document, options)
  #   Allow an extention point where information in the document
  #   may drive the value of the field
  #   @param [SolrDocument] doc
  #   @param [Hash] opts
  #   @options opts [String] :field
  def render_document_show_field_label *args
    options = args.extract_options!
    document = args.first

    field = options[:field]

    t(:'blacklight.search.show.label', label: document_show_field_label(document, field))
  end

  ##
  # Render the index field label for a document
  #
  # @overload render_document_show_field_value(options)
  #   Use the default, document-agnostic configuration
  #   @param [Hash] opts
  #   @options opts [String] :field
  #   @options opts [String] :value
  #   @options opts [String] :document
  # @overload render_document_show_field_value(document, options)
  #   Allow an extention point where information in the document
  #   may drive the value of the field
  #   @param [SolrDocument] doc
  #   @param [Hash] opts
  #   @options opts [String] :field
  #   @options opts [String] :value
  # @overload render_document_show_field_value(document, field, options)
  #   Allow an extention point where information in the document
  #   may drive the value of the field
  #   @param [SolrDocument] doc
  #   @param [String] field
  #   @param [Hash] opts
  #   @options opts [String] :value
  def render_document_show_field_value *args
    options = args.extract_options!
    document = args.shift || options[:document]

    field = args.shift || options[:field]
    presenter(document).render_document_show_field_value field, options.except(:document, :field)
  end

  ##
  # Get the value of the document's "title" field, or a placeholder
  # value (if empty)
  #
  # @param [SolrDocument] document
  # @return [String]
  def document_heading document=nil
    document ||= @document
    presenter(document).document_heading
  end

  ##
  # Get the document's "title" to display in the <title> element.
  # (by default, use the #document_heading)
  #
  # @see #document_heading
  # @param [SolrDocument] document
  # @return [String]
  def document_show_html_title document=nil
    document ||= @document

    presenter(document).document_show_html_title
  end

  ##
  # Render the document "heading" (title) in a content tag
  # @overload render_document_heading(document, options)
  #   @params [SolrDocument] document
  #   @params [Hash] options
  #   @options options [Symbol] :tag
  # @overload render_document_heading(options)
  #   @params [Hash] options
  #   @options options [Symbol] :tag
  def render_document_heading(*args)
    options = args.extract_options!
    document = args.first
    tag = options.fetch(:tag, :h4)
    document = document || @document

    content_tag(tag, presenter(document).document_heading, itemprop: "name")
  end

  ##
  # Get the value for a document's field, and prepare to render it.
  # - highlight_field
  # - accessor
  # - solr field
  #
  # Rendering:
  #   - helper_method
  #   - link_to_search
  # TODO : maybe this should be merged with render_field_value, and the ugly signature
  # simplified by pushing some of this logic into the "model"
  # @param [SolrDocument] document
  # @param [String] field name
  # @param [Blacklight::Solr::Configuration::Field] solr field configuration
  # @param [Hash] options additional options to pass to the rendering helpers
  def get_field_values document, field, field_config, options = {}
    presenter(document).get_field_values field, field_config, options
  end

  ##
  # Get the current "view type" (and ensure it is a valid type)
  #
  # @param [Hash] the query parameters to check
  # @return [Symbol]
  def document_index_view_type query_params=params
    view_param = query_params[:view]
    view_param ||= session[:preferred_view]
    if view_param and document_index_views.keys.include? view_param.to_sym
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
  def with_format(format, &block)
    old_formats = formats
    self.formats = [format]
    block.call
    self.formats = old_formats
    nil
  end

  ##
  # Should we render a grouped response (because the response
  # contains a grouped response instead of the normal response)
  def render_grouped_response? response = @response
    return response.grouped?
  end

  ##
  # Determine whether to render the bookmarks control
  def render_bookmarks_control?
    has_user_authentication_provider? and current_or_guest_user.present?
  end

  ##
  # Determine whether to render the saved searches link
  def render_saved_searches?
    has_user_authentication_provider? and current_user
  end

  ##
  # Returns a document presenter for the given document
  def presenter(document)
    presenter_class.new(document, self)
  end

  ##
  # Override this method if you want to use a different presenter class
  def presenter_class
    blacklight_config.document_presenter_class
  end

  ##
  # Open Search discovery tag for HTML <head> links
  def opensearch_description_tag title, href
    tag :link, href: href, title: title, type: "application/opensearchdescription+xml", rel: "search"
  end
end
