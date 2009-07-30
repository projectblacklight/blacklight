#
# Methods added to this helper will be available to all templates in the application.
#
module ApplicationHelper
  
  def application_name
    'Blacklight'
  end
  
  # collection of items to be rendered in the @sidebar
  def sidebar_items
    @sidebar_items ||= []
  end
  
  #
  # Blacklight.config based helpers ->
  #
  
  # used in the catalog/_facets partial
  def facet_field_labels
    Blacklight.config[:facet][:labels]
  end
  
  # used in the catalog/_facets partial
  def facet_field_names
    Blacklight.config[:facet][:field_names]
  end
  
  # used in the catalog/_index_partials/_default view
  def index_field_names
    Blacklight.config[:index_fields][:field_names]
  end
  
  # used in the _index_partials/_default view
  def index_field_labels
    Blacklight.config[:index_fields][:labels]
  end
  
  # Used in the show view for displaying the main solr document heading
  def document_heading
    @document[Blacklight.config[:show][:heading]]
  end
  
  # Used in the show view for setting the main html document title
  def document_show_html_title
    @document[Blacklight.config[:show][:html_title]]
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
    Blacklight.config[:search_fields]
  end
  
  # used in the catalog/_show/_default partial
  def document_show_fields
    Blacklight.config[:show_fields][:field_names]
  end
  
  # used in the catalog/_show/_default partial
  def document_show_field_labels
    Blacklight.config[:show_fields][:labels]
  end
  
  # currently only used by the render_document_partial helper method (below)
  def document_partial_name(document)
    document[Blacklight.config[:show][:display_type]]
  end
  
  # given a doc and action_name, this method attempts to render a partial template
  # based on the value of doc[:format_code_t]
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
    query_part = params[:qt] == Blacklight.config[:default_qt] ? params[:q] : "#{params[:qt]}:(#{params[:q]})"
    facet_part = 
    if params[:f]
      tmp = 
      params[:f].collect do |pair|
        "#{Blacklight.config[:facet][:labels][pair.first]}:#{pair.last}"
      end.join(" AND ")
      "{#{tmp}}"
    else
      ""
    end
    link_to("#{query_part} #{facet_part}", catalog_index_path(params))
  end
  
  #
  # Export Helpers
  #
  def render_refworks_text(record)
    if record.marc.marc
      fields = record.marc.marc.find_all { |f| ('000'..'999') === f.tag }
      text = "LEADER #{record.marc.marc.leader}"
      fields.each do |field|
        unless ["940","999"].include?(field.tag)
          if field.is_a?(MARC::ControlField)
            text << "#{field.tag}    #{field.value}\n"
          else
            text << "#{field.tag} "
            text << (field.indicator1 ? field.indicator1 : " ")
            text << (field.indicator2 ? field.indicator2 : " ")
            text << " "
            field.each {|s| s.code == 'a' ? text << "#{s.value}" : text << " |#{s.code}#{s.value}"}
            text << "\n"
          end
        end
      end
      text
    end 
  end
  def render_endnote_text(record)
    end_note_format = {
      "%A" => "100.a",
      "%C" => "260.b",
      "%D" => "260.c",
      "%E" => "700.a",
      "%I" => "260.a",
      "%J" => "440.a",
      "%@" => "020.a",
      "%_@" => "022.a",
      "%T" => "245.a,245.b",
      "%U" => "856.u",
      "%7" => "250.a"
    }
    marc = record.marc.marc
    text = ''
    text << "%0 #{document_partial_name(record)}\n"
    # If there is some reliable way of getting the language of a record we can add it here
    #text << "%G #{record['language'].first}\n"
    end_note_format.each do |key,value|
      values = value.split(",")
      first_value = values[0].split('.')
      if values.length > 1
        second_value = values[1].split('.')
      else
        second_value = []
      end
      
      if marc[first_value[0].to_s]
        marc.find_all{|f| (first_value[0].to_s) === f.tag}.each do |field|
          if field[first_value[1]].to_s or field[second_value[1]].to_s
            text << "#{key.gsub('_','')}"
            if field[first_value[1]].to_s
              text << " #{field[first_value[1]].to_s}"
            end
            if field[second_value[1]].to_s
              text << " #{field[second_value[1]].to_s}"
            end
            text << "\n"
          end
        end
      end
    end
    text
  end
  
  #
  # facet param helpers ->
  #
  
  # adds the value and/or field to params[:f]
  def add_facet_params(field, value)
    p = params.dup
    p.delete :page
    p[:f]||={}
    p[:f][field] ||= []
    p[:f][field].push(value)
    p
  end
  
  # copies the current params (or whatever is passed in as the 3rd arg)
  # removes the field value from params[:f]
  # removes the field if there are no more values in params[:f][field]
  # removes additional params (page, id, etc..)
  def remove_facet_params(field, value, source_params=params)
    p = source_params.dup.symbolize_keys!
    # need to dup the facet values too,
    # if the values aren't dup'd, then the values
    # from the session will get remove in the show view...
    p[:f] = p[:f].dup.symbolize_keys!
    p.delete :page
    p.delete :id
    p.delete :counter
    p.delete :commit
    #return p unless p[field]
    p[:f][field] = p[:f][field] - [value]
    p[:f].delete(field) if p[:f][field].size == 0
    p
  end
  
  # true or false, depending on whether the field and value is in params[:f]
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
    query_params = session[:search].dup || {}
    query_params.delete :counter
    query_params.delete :total
    link_url = catalog_index_path(query_params)
    link_to opts[:label], link_url
  end

  def link_to_previous_document(previous_document)
    return if previous_document == nil
    link_to_document previous_document, :label=>'< Previous', :counter => session[:search][:counter].to_i - 1
  end

  def link_to_next_document(next_document)
    return if next_document == nil
    link_to_document next_document, :label=>'Next >', :counter => session[:search][:counter].to_i + 1
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
      "<a #{href_attr}#{tag_options}>#{h(name) || h(url)}</a>"
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
  
  # performs an XSLT transform
  def xslt(stylesheet_file_path, document, params={})
    require 'nokogiri'
    document = Nokogiri::XML(document) if document.is_a?(String)
    stylesheet = Nokogiri::XSLT.parse(render(stylesheet_file_path))
    stylesheet.apply_to(Nokogiri::XML(document.to_xml), params)
  end
  
end