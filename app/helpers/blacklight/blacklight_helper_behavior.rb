# -*- encoding : utf-8 -*-
# -*- coding: utf-8 -*-
#
# Methods added to this helper will be available to all templates in the hosting application
#
module Blacklight::BlacklightHelperBehavior
  include BlacklightUrlHelper
  include HashAsHiddenFieldsHelper
  include RenderConstraintsHelper
  include FacetsHelper

  def application_name
    return Rails.application.config.application_name if Rails.application.config.respond_to? :application_name

    t('blacklight.application_name')
  end

  # Create <link rel="alternate"> links from a documents dynamically
  # provided export formats. Currently not used by standard BL layouts,
  # but available for your custom layouts to provide link rel alternates.
  #
  # Returns empty string if no links available.
  #
  # :unique => true, will ensure only one link is output for every
  # content type, as required eg in atom. Which one 'wins' is arbitrary.
  # :exclude => array of format shortnames, formats to not include at all.
  def render_link_rel_alternates(document=@document, options = {})
    options = {:unique => false, :exclude => []}.merge(options)

    return nil if document.nil?

    seen = Set.new

    html = ""
    document.export_formats.each_pair do |format, spec|
      unless( options[:exclude].include?(format) ||
             (options[:unique] && seen.include?(spec[:content_type]))
             )
        html << tag(:link, {:rel=>"alternate", :title=>format, :type => spec[:content_type], :href=> polymorphic_url(document, :format => format)}) << "\n"

        seen.add(spec[:content_type]) if options[:unique]
      end
    end
    return html.html_safe
  end

  def render_opensearch_response_metadata
    render :partial => 'catalog/opensearch_response_metadata'
  end

  def render_body_class
    extra_body_classes.join " "
  end

  def render_search_bar
    render :partial=>'catalog/search_form'
  end

  def extra_body_classes
    @extra_body_classes ||= ['blacklight-' + controller.controller_name, 'blacklight-' + [controller.controller_name, controller.action_name].join('-')]
  end

  def render_document_list_partial options={}
    render :partial=>'catalog/document_list'
  end

  # Save function area for search results 'index' view, normally
  # renders next to title.
  def render_index_doc_actions(document, options={})
    wrapping_class = options.delete(:wrapping_class) || "index-document-functions"

    content = []
    content << render(:partial => 'catalog/bookmark_control', :locals => {:document=> document}.merge(options)) if render_bookmarks_control?

    content_tag("div", safe_join(content, "\n"), :class=> wrapping_class)
  end

  ##
  # Render "docuemnt actions" for the item detail 'show' view.
  # (this normally renders next to title)
  #
  # By default includes 'Bookmarks'
  # 
  # @param [SolrDocument] document
  # @param [Hash] options
  # @option options [String] :wrapping_class
  # @return [String]
  def render_show_doc_actions(document=@document, options={})
    wrapping_class = options.delete(:wrapping_class) || "documentFunctions"

    content = []
    content << render(:partial => 'catalog/bookmark_control', :locals => {:document=> document}.merge(options)) if render_bookmarks_control?

    content_tag("div", safe_join(content, "\n"), :class=> wrapping_class)
  end

  ##
  # Index fields to display for a type of document
  def index_fields document=nil
    blacklight_config.index_fields
  end

  def should_render_index_field? document, solr_field
    document.has?(solr_field.field) ||
      (document.has_highlight_field? solr_field.field if solr_field.highlight) ||
      solr_field.accessor
  end

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
    html_escape t(:'blacklight.search.index.label', label: index_fields(document)[field].label)
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
    field_config = index_fields(document)[field]
    value = options[:value] || get_field_values(document, field, field_config, options)


    render_field_value value, field_config
  end

  # Used in the show view for displaying the main solr document heading
  def document_heading document=nil
    document ||= @document
    render_field_value document[blacklight_config.view_config(:show).title_field] || document.id
  end

  # Used in the show view for setting the main html document title
  def document_show_html_title document=nil
    document ||= @document

    if blacklight_config.view_config(:show).html_title_field
      render_field_value(document[blacklight_config.view_config(:show).html_title_field])
    else
      document_heading document
    end
  end

  ##
  # Render the document "heading" (title) in a content tag
  # @overload render_document_heading(tag)
  # @overload render_document_heading(document, options)
  #   @params [SolrDocument] document
  #   @params [Hash] options
  #   @options options [Symbol] :tag
  def render_document_heading(*args)
    options = args.extract_options!
    if args.first.is_a? SolrDocument
      document = args.shift
      tag = options[:tag]
    else
      document = nil
      tag = args.first || options[:tag]
    end

    tag ||= :h4

    content_tag(tag, render_field_value(document_heading(document)), :itemprop => "name")
  end

  # Used in the document_list partial (search view) for building a select element
  def sort_fields
    blacklight_config.sort_fields.map { |key, x| [x.label, x.key] }
  end

  # Used in the document list partial (search view) for creating a link to the document show action
  def document_show_link_field document=nil
    blacklight_config.view_config(document_index_view_type).title_field.to_sym
  end

  # Used in the search form partial for building a select tag
  def search_fields
    search_field_options_for_select
  end

  # used in the catalog/_show/_default partial
  def document_show_fields document=nil
    blacklight_config.show_fields
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

    html_escape t(:'blacklight.search.show.label', label: document_show_fields(document)[field].label)
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
    field_config = document_show_fields(document)[field]
    value = options[:value] || get_field_values(document, field, field_config, options)

    render_field_value value, field_config
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
  def get_field_values document, field, field_config, options = {}
    # valuyes
    value = case    
      when (field_config and field_config.highlight)
        # retrieve the document value from the highlighting response
        document.highlight_field(field_config.field).map { |x| x.html_safe } if document.has_highlight_field? field_config.field
      when (field_config and field_config.accessor)
        # implicit method call
        if field_config.accessor === true
          document.send(field)
        # arity-1 method call (include the field name in the call)
        elsif !field_config.accessor.is_a?(Array) && document.method(field_config.accessor).arity != 0
          document.send(field_config.accessor, field)
        # chained method calls
        else
          Array(field_config.accessor).inject(document) do |result, method|
            result.send(method)
          end
        end
      else
        # regular solr
        document.get(field, :sep => nil) if field
    end

    # rendering
    case
      when (field_config and field_config.helper_method)
        send(field_config.helper_method, options.merge(:document => document, :field => field, :value => value))
      when (field_config and field_config.link_to_search)
        link_field = if field_config.link_to_search === true
          field_config.field
        else
          field_config.link_to_search
        end

        Array(value).map do |v|
          link_to render_field_value(v, field_config), search_action_url(add_facet_params(link_field, v, {}))
        end if field
      else
        value
      end
  end

  def should_render_show_field? document, solr_field
    document.has?(solr_field.field) ||
      (document.has_highlight_field? solr_field.field if solr_field.highlight) ||
      solr_field.accessor
  end

  def render_field_value value=nil, field_config=nil
    safe_values = Array(value).collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x }

    if field_config and field_config.itemprop
      safe_values = safe_values.map { |x| content_tag :span, x, :itemprop => field_config.itemprop }
    end

    safe_join(safe_values, (field_config.separator if field_config) || field_value_separator)
  end

  def field_value_separator
    ', '
  end

  def document_index_view_type query_params=params
    if query_params[:view] and blacklight_config.view.keys.include? query_params[:view].to_sym
      query_params[:view].to_sym
    else
      default_document_index_view_type
    end
  end

  def default_document_index_view_type
    blacklight_config.view.keys.first
  end

  def render_document_index documents = nil, locals = {}
    documents ||= @document_list
    render_document_index_with_view(document_index_view_type, documents)
  end

  def render_document_index_with_view view, documents, locals = {}
    document_index_path_templates.each do |str|
      # XXX rather than handling this logic through exceptions, maybe there's a Rails internals method
      # for determining if a partial template exists..
      begin
        return render(:partial => (str % { :index_view_type => view }), :locals => locals.merge(:documents => documents) )
      rescue ActionView::MissingTemplate
        nil
      end
    end

    return ""
  end

  # a list of document partial templates to try to render for #render_document_index
  def document_index_path_templates
    # first, the legacy template names for backwards compatbility
    # followed by the new, inheritable style
    # finally, a controller-specific path for non-catalog subclasses
    @document_index_path_templates ||= ["document_%{index_view_type}", "catalog/document_%{index_view_type}", "catalog/document_list"]
  end

  # Return a normalized partial name that can be used to contruct view partial path
  def document_partial_name(document)
    # .to_s is necessary otherwise the default return value is not always a string
    # using "_" as sep. to more closely follow the views file naming conventions
    # parameterize uses "-" as the default sep. which throws errors
    display_type = document[blacklight_config.view_config(:show).display_type_field]

    return 'default' unless display_type
    display_type = display_type.join(" ") if display_type.respond_to?(:join)

    "#{display_type.gsub("-"," ")}".parameterize("_").to_s
  end

  def render_document_partials(doc, actions = [], locals ={})
    safe_join(actions.map do |action_name|
      render_document_partial(doc, action_name, locals)
    end, "\n")
  end

  # given a doc and action_name, this method attempts to render a partial template
  # based on the value of doc[:format]
  # if this value is blank (nil/empty) the "default" is used
  # if the partial is not found, the "default" partial is rendered instead
  def render_document_partial(doc, action_name, locals = {})
    format = document_partial_name(doc)

    document_partial_path_templates.each do |str|
      # XXX rather than handling this logic through exceptions, maybe there's a Rails internals method
      # for determining if a partial template exists..
      begin
        return render :partial => (str % { :action_name => action_name, :format => format, :index_view_type => document_index_view_type }), :locals=>locals.merge({:document=>doc})
      rescue ActionView::MissingTemplate
        nil
      end
    end

    return ''
  end

  # a list of document partial templates to try to render for #render_document_partial
  def document_partial_path_templates
    # first, the legacy template names for backwards compatbility
    # followed by the new, inheritable style
    # finally, a controller-specific path for non-catalog subclasses
    @partial_path_templates ||= ["%{action_name}_%{index_view_type}_%{format}", "%{action_name}_%{index_view_type}_default", "%{action_name}_%{format}", "%{action_name}_default", "catalog/%{action_name}_%{format}", "catalog/_%{action_name}_partials/%{format}", "catalog/_%{action_name}_partials/default"]
  end



  def render_document_index_label doc, opts
    label = nil
    label ||= doc.get(opts[:label], :sep => nil) if opts[:label].instance_of? Symbol
    label ||= opts[:label].call(doc, opts) if opts[:label].instance_of? Proc
    label ||= opts[:label] if opts[:label].is_a? String
    label ||= doc.id
    render_field_value label
  end

  # Use case, you want to render an html partial from an XML (say, atom)
  # template. Rails API kind of lets us down, we need to hack Rails internals
  # a bit. code taken from:
  # http://stackoverflow.com/questions/339130/how-do-i-render-a-partial-of-a-different-format-in-rails (zgchurch)
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
  # Render the grouped response
  def render_grouped_document_index grouped_key = nil
    render :partial => 'catalog/group_default'
  end

  def render_bookmarks_control?
    has_user_authentication_provider? and current_or_guest_user.present?
  end

  def spell_check_max
    blacklight_config.spell_max
  end

end
