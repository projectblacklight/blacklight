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
	  format = doc[DisplayFields.show_view[:display_type].to_sym].blank? ? 'default' : doc[DisplayFields.show_view[:display_type].to_sym]
	  begin
	    render :partial=>"catalog/_#{action_name}_partials/#{format}", :locals=>{:document=>doc}
    rescue ActionView::MissingTemplate
      render :partial=>"catalog/_#{action_name}_partials/default", :locals=>{:document=>doc}
    end
  end
	
	# link_to_document(doc, :label=>'VIEW', :counter => 3)
	# Use the catalog_path RESTful route to create a link to the show page for a specific item. 
	# catalog_path accepts a HashWithIndifferentAccess object. The solr query params are stored in the session,
	# so we only need the +counter+ param here, which is passed in the +extra_params+ hash.
	def link_to_document(doc, opts={:label=>DisplayFields.index_view[:show_link].to_sym, :extra_params=>{}})
	  label = case opts[:label]
    when Symbol
      doc.get(opts[:label])
    when String
      opts[:label]
    else
      raise 'Invalid label argument'
    end
    link_to label, catalog_path(doc[:id], opts[:extra_params])
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
	  	link_to_document previous_document, :label=>'&lt; Previous', :extra_params=>{:counter => params[:counter].to_i - 1}
  end
  
  def link_to_next_document(next_document)
    return if next_document == nil
    link_to_document next_document, :label=>'Next &gt;', :extra_params=>{:counter => params[:counter].to_i + 1}
  end
	
end