module CatalogHelper
  
  # adds the value and/or field to params[:f]
  def add_facet_params(field, value)
    p = params.dup
    p.delete :page
    p[:f]||={}
    p[:f][field] ||= []
    p[:f][field].push(value)
    p
  end
  
  # copies the current params
  # removes the field value from params[:f]
  # removes the field if there are no more values in params[:f][field]
  # removes the :page param
  def remove_facet_params(field, value)
    p=params.dup
    p.delete :page
    p[:f][field] = p[:f][field] - [value]
    p[:f].delete(field) if p[:f][field].size == 0
    p
  end
  
  # true or false, depending on wether the field and value is in params[:f]
  def facet_in_params?(field, value)
    params[:f] and params[:f][field] and params[:f][field].include?(value)
  end
  
  # NOTE: as of 2009-04-20, this is only used for facet.html.erb, which
  #  is facet pagination ... and it probably shouldn't be used there.
  # creates a formatted label for a field (removes _facet and _display etc.)
  def field_label(field)
    @__field_label_cache ||= {}
    @__field_label_cache[field] ||= field.to_s.sub(/_facet$|_display$|_[a-z]$/,'').gsub(/_/,' ')
    @__field_label_cache[field]
  end

  #
  # shortcut for built-in Rails helper, "number_with_delimiter"
  #
  def format_num(num); number_with_delimiter(num) end

  # given a doc and action_name, this method attempts to render a partial template
  # based on the value of doc[:format_code_t]
  # if this value is blank (nil/empty) the "default" is used
  # if the partial is not found, the "default" partial is rendered instead
  def render_document_partial(doc, action_name)
    format = doc[Blacklight.config[:show][:display_type].to_sym].blank? ? 'default' : doc[Blacklight.config[:show][:display_type].to_sym]
    begin
      render :partial=>"catalog/_#{action_name}_partials/#{format}", :locals=>{:document=>doc}
    rescue ActionView::MissingTemplate
      render :partial=>"catalog/_#{action_name}_partials/default", :locals=>{:document=>doc}
    end
  end

  # link_to_document(doc, :label=>'VIEW', :counter => 3)
  # Use the catalog_path RESTful route to create a link to the show page for a specific item. 
  # catalog_path accepts a HashWithIndifferentAccess object. The solr query params are stored in the session,
  # so we only need the +counter+ param here.
  def link_to_document(doc, opts={:label=>Blacklight.config[:index][:show_link].to_sym, :counter => nil})
    label = case opts[:label]
    when Symbol
      doc.get(opts[:label])
    when String
      opts[:label]
    else
      raise 'Invalid label argument'
    end
    link_to_with_data(label, catalog_path(doc[:id]), {:method => :put, :data => {:counter => opts[:counter]}})
  end

  # link_back_to_catalog(:label=>'Back to Search')
  # Create a link back to the index screen, keeping the user's facet, query and paging choices intact by using session.
  def link_back_to_catalog(opts={:label=>'Back to Search'})
    query_params = session[:search] || {}
    link_url = catalog_index_path(query_params)
    link_to opts[:label], link_url
  end

  def link_to_previous_document(previous_document)
    return if previous_document == nil
    link_to_document previous_document, :label=>'&lt; Previous', :counter => session[:search][:counter].to_i - 1
  end

  def link_to_next_document(next_document)
    return if next_document == nil
    link_to_document next_document, :label=>'Next &gt;', :counter => session[:search][:counter].to_i + 1
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
      "<a #{href_attr}#{tag_options}>#{name || url}</a>"
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
      "this.parentNode.appendChild(f); f.method = 'POST'; f.action = #{action};"

    if data
      data.each_pair do |key, value|
        submit_function << "var d = document.createElement('input'); d.setAttribute('type', 'hidden'); "
        submit_function << "d.setAttribute('name', '#{key}'); d.setAttribute('value', '#{value}'); f.appendChild(d);"
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


end