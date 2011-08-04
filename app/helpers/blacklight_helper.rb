# -*- encoding : utf-8 -*-
# -*- coding: utf-8 -*-
#
# Methods added to this helper will be available to all templates in the hosting application
#
module BlacklightHelper
  include HashAsHiddenFields
  include RenderConstraintsHelper
  include HtmlHeadHelper
  include FacetsHelper

  
  def application_name
    'Blacklight'
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
        html << tag(:link, {:rel=>"alternate", :title=>format, :type => spec[:content_type], :href=> catalog_url(document.id,  format)}) << "\n"
        
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
  
  # collection of items to be rendered in the @sidebar
  def sidebar_items
    @sidebar_items ||= []
  end

  def extra_body_classes
    @extra_body_classes ||= ['blacklight-' + controller.controller_name, 'blacklight-' + [controller.controller_name, controller.action_name].join('-')]
  end
  
  
  def render_document_list_partial options={}
    render :partial=>'catalog/document_list'
  end
  
  # Save function area for search results 'index' view, normally
  # renders next to title. Includes just 'Folder' by default.
  def render_index_doc_actions(document, options={})   
    content_tag("div", :class=>"documentFunctions") do
      raw("#{render(:partial => 'bookmark_control', :locals => {:document=> document}.merge(options))}
       #{render(:partial => 'folder_control', :locals => {:document=> document}.merge(options))}")
    end
  end
  
  # Save function area for item detail 'show' view, normally
  # renders next to title. By default includes 'Folder' and 'Bookmarks'
  def render_show_doc_actions(document=@document, options={})
    content_tag("div", :class=>"documentFunctions") do
      raw("#{render(:partial => 'bookmark_control', :locals => {:document=> document}.merge(options))}
       #{render(:partial => 'folder_control', :locals => {:document=> document}.merge(options))}")
    end
  end
  
  # used in the catalog/_index_partials/_default view
  def index_field_names
    Blacklight.config[:index_fields][:field_names]
  end
  
  # used in the _index_partials/_default view
  def index_field_labels
    Blacklight.config[:index_fields][:labels]
  end

  def spell_check_max
    Blacklight.config[:spell_max] || 0
  end

  def render_index_field_label args
    field = args[:field]
    html_escape index_field_labels[field]
  end

  def render_index_field_value args
    value = args[:value]
    value ||= args[:document].get(args[:field], :sep => nil) if args[:document] and args[:field]
    render_field_value value
  end
  
  # Used in the show view for displaying the main solr document heading
  def document_heading
    @document[Blacklight.config[:show][:heading]] || @document.id
  end
  def render_document_heading
    content_tag(:h1, document_heading)
  end
  
  # Used in the show view for setting the main html document title
  def document_show_html_title
    @document[Blacklight.config[:show][:html_title]]
  end
  
  # Used in citation view for displaying the title
  def citation_title(document)
    document[Blacklight.config[:show][:html_title]]
  end
  
  # Used in the document_list partial (search view) for building a select element
  def sort_fields
    Blacklight.config[:sort_fields]
  end
  
  # Used in the document list partial (search view) for creating a link to the document show action
  def document_show_link_field
    Blacklight.config[:index][:show_link].to_sym
  end
  
  # Used in the search form partial for building a select tag
  def search_fields
    Blacklight.search_field_options_for_select
  end
  
  # used in the catalog/_show/_default partial
  def document_show_fields
    Blacklight.config[:show_fields][:field_names]
  end
  
  # used in the catalog/_show/_default partial
  def document_show_field_labels
    Blacklight.config[:show_fields][:labels]
  end

  def render_document_show_field_label args 
    field = args[:field]
    html_escape document_show_field_labels[field]
  end

  def render_document_show_field_value args
    value = args[:value]
    value ||= args[:document].get(args[:field], :sep => nil) if args[:document] and args[:field]
    render_field_value value
  end

  def render_field_value value=nil
    value = [value] unless value.is_a? Array
    value = value.collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x}
    return value.map { |v| html_escape v }.join(field_value_separator).html_safe
  end  

  def field_value_separator
    ', '
  end
  
  # Return a normalized partial name that can be used to contruct view partial path
  def document_partial_name(document)
    # .to_s is necessary otherwise the default return value is not always a string
    # using "_" as sep. to more closely follow the views file naming conventions
    # parameterize uses "-" as the default sep. which throws errors
    display_type = document[Blacklight.config[:show][:display_type]]

    return 'default' unless display_type
    display_type = display_type.join(" ") if display_type.respond_to?(:join)

    "#{display_type.gsub("-"," ")}".parameterize("_").to_s
  end

  # given a doc and action_name, this method attempts to render a partial template
  # based on the value of doc[:format]
  # if this value is blank (nil/empty) the "default" is used
  # if the partial is not found, the "default" partial is rendered instead
  def render_document_partial(doc, action_name)
    format = document_partial_name(doc)
    begin
      render :partial=>"catalog/_#{action_name}_partials/#{format}", :locals=>{:document=>doc}
    rescue ActionView::MissingTemplate
      render :partial=>"catalog/_#{action_name}_partials/default", :locals=>{:document=>doc}
    end
  end
  
  # Search History and Saved Searches display
  def link_to_previous_search(params)
    link_to(raw(render_search_to_s(params)), catalog_index_path(params)).html_safe
  end
    
  #
  # shortcut for built-in Rails helper, "number_with_delimiter"
  #
  def format_num(num); number_with_delimiter(num) end
  
  #
  # link based helpers ->
  #
  
  # create link to query (e.g. spelling suggestion)
  def link_to_query(query)
    p = params.dup
    p.delete :page
    p.delete :action
    p[:q]=query
    link_url = catalog_index_path(p)
    link_to(query, link_url)
  end
  
  def render_document_index_label doc, opts
    label = nil
    label ||= doc.get(opts[:label]) if opts[:label].instance_of? Symbol
    label ||= opts[:label].call(doc, opts) if opts[:label].instance_of? Proc
    label ||= opts[:label] if opts[:label].is_a? String
    label ||= doc.id
  end

  # link_to_document(doc, :label=>'VIEW', :counter => 3)
  # Use the catalog_path RESTful route to create a link to the show page for a specific item. 
  # catalog_path accepts a HashWithIndifferentAccess object. The solr query params are stored in the session,
  # so we only need the +counter+ param here. We also need to know if we are viewing to document as part of search results.
  def link_to_document(doc, opts={:label=>Blacklight.config[:index][:show_link].to_sym, :counter => nil, :results_view => true})
    label = render_document_index_label doc, opts
    link_to_with_data(label, catalog_path(doc.id), {:method => :put, :class => label.parameterize, :data => opts}).html_safe
  end

  # link_back_to_catalog(:label=>'Back to Search')
  # Create a link back to the index screen, keeping the user's facet, query and paging choices intact by using session.
  def link_back_to_catalog(opts={:label=>'Back to Search'})
    query_params = session[:search] ? session[:search].dup : {}
    query_params.delete :counter
    query_params.delete :total
    link_url = catalog_index_path + "?" + query_params.to_query
    link_to opts[:label], link_url
  end
  
  # Create form input type=hidden fields representing the entire search context,
  # for inclusion in a form meant to change some aspect of it, like
  # re-sort or change records per page. Can pass in params hash
  # as :params => hash, otherwise defaults to #params. Can pass
  # in certain top-level params keys to _omit_, defaults to :page
  def search_as_hidden_fields(options={})
    
    options = {:params => params, :omit_keys => [:page]}.merge(options)
    my_params = options[:params].dup
    options[:omit_keys].each {|omit_key| my_params.delete(omit_key)}
    # removing action and controller from duplicate params so that we don't get hidden fields for them.
    my_params.delete(:action)
    my_params.delete(:controller)
    # commit is just an artifact of submit button, we don't need it, and
    # don't want it to pile up with another every time we press submit again!
    my_params.delete(:commit)
    # hash_as_hidden_fields in hash_as_hidden_fields.rb
    return hash_as_hidden_fields(my_params)
  end
  
    

  def link_to_previous_document(previous_document)
    return if previous_document == nil
    link_to_document previous_document, :label=>'« Previous', :counter => session[:search][:counter].to_i - 1
  end

  def link_to_next_document(next_document)
    return if next_document == nil
    link_to_document next_document, :label=>'Next »', :counter => session[:search][:counter].to_i + 1
  end

  # Use case, you want to render an html partial from an XML (say, atom)
  # template. Rails API kind of lets us down, we need to hack Rails internals 
  # a bit. code taken from:
  # http://stackoverflow.com/questions/339130/how-do-i-render-a-partial-of-a-different-format-in-rails
  def with_format(format, &block)
    old_format = @template_format
    @template_format = format
    result = block.call
    @template_format = old_format
    return result
  end
  

  # This is an updated +link_to+ that allows you to pass a +data+ hash along with the +html_options+
  # which are then written to the generated form for non-GET requests. The key is the form element name
  # and the value is the value:
  #
  #  link_to_with_data('Name', some_path(some_id), :method => :post, :html)
  def link_to_with_data(*args, &block)
    if block_given?
      options      = args.first || {}
      html_options = args.second
      concat(link_to(capture(&block), options, html_options))
    else
      name         = args.first
      options      = args.second || {}
      html_options = args.third

      url = url_for(options)

      if html_options
        html_options = html_options.stringify_keys
        href = html_options['href']
        convert_options_to_javascript_with_data!(html_options, url)
        tag_options = tag_options(html_options)
      else
        tag_options = nil
      end

      href_attr = "href=\"#{url}\"" unless href
      "<a #{href_attr}#{tag_options}>#{h(name) || h(url)}</a>".html_safe
    end
  end

  # This is derived from +convert_options_to_javascript+ from module +UrlHelper+ in +url_helper.rb+
  def convert_options_to_javascript_with_data!(html_options, url = '')
    confirm, popup = html_options.delete("confirm"), html_options.delete("popup")

    method, href = html_options.delete("method"), html_options['href']
    data = html_options.delete("data")
    data = data.stringify_keys if data
    
    html_options["onclick"] = case
      when method
        "#{method_javascript_function_with_data(method, url, href, data)}return false;"
      else
        html_options["onclick"]
    end
  end

  # This is derived from +method_javascript_function+ from module +UrlHelper+ in +url_helper.rb+
  def method_javascript_function_with_data(method, url = '', href = nil, data=nil)
    action = (href && url.size > 0) ? "'#{url}'" : 'this.href'
    submit_function =
      "var f = document.createElement('form'); f.style.display = 'none'; " +
      "this.parentNode.appendChild(f); f.method = 'POST'; f.action = #{action};"+
      "if(event.metaKey || event.ctrlKey){f.target = '_blank';};" # if the command or control key is being held down while the link is clicked set the form's target to _blank
    if data
      data.each_pair do |key, value|
        submit_function << "var d = document.createElement('input'); d.setAttribute('type', 'hidden'); "
        submit_function << "d.setAttribute('name', '#{key}'); d.setAttribute('value', '#{escape_javascript(value.to_s)}'); f.appendChild(d);"
      end
    end
    unless method == :post
      submit_function << "var m = document.createElement('input'); m.setAttribute('type', 'hidden'); "
      submit_function << "m.setAttribute('name', '_method'); m.setAttribute('value', '#{method}'); f.appendChild(m);"
    end

    if protect_against_forgery?
      submit_function << "var s = document.createElement('input'); s.setAttribute('type', 'hidden'); "
      submit_function << "s.setAttribute('name', '#{request_forgery_protection_token}'); s.setAttribute('value', '#{escape_javascript form_authenticity_token}'); f.appendChild(s);"
    end
    submit_function << "f.submit();"
  end
  
  # determines if the given document id is in the folder
  def item_in_folder?(doc_id)
    session[:folder_document_ids] && session[:folder_document_ids].include?(doc_id) ? true : false
  end
  
  # puts together a collection of documents into one refworks export string
  def render_refworks_texts(documents)
    val = ''
    documents.each do |doc|
      if doc.respond_to?(:to_marc)
        val += doc.export_as_refworks_marc_txt + "\n"
      end
    end
    val
  end
  
  # puts together a collection of documents into one endnote export string
  def render_endnote_texts(documents)
    val = ''
    documents.each do |doc|
      if doc.respond_to?(:to_marc)
        val += doc.export_as_endnote + "\n"
      end
    end
    val
  end

end
