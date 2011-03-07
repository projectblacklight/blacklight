module CatalogHelper
  #
  	# shortcut for built-in Rails helper, "number_with_delimiter"
  	#
  	def format_num(num); number_with_delimiter(num) end

  	#
  	# Displays the "showing X through Y of N" message. Not sure
    # why that's called "page_entries_info". Not entirely sure
    # what collection argument is supposed to duck-type too, but
    # an RSolr::Ext::Response works.  Perhaps it duck-types to something
    # from will_paginate?
  	def page_entries_info(collection, options = {})
      start = (collection.current_page - 1) * collection.per_page + 1
      total_hits = @response.total
      start_num = format_num(start)
      end_num = format_num(start + collection.size - 1)
      total_num = format_num(total_hits)
    #  end_num = total_num if total_hits < (start + collection.per_page - 1)

      entry_name = options[:entry_name] ||
        (collection.empty?? 'entry' : collection.first.class.name.underscore.sub('_', ' '))

      if collection.total_pages < 2
        case collection.size
        when 0; "No #{h(entry_name.pluralize)} found".html_safe
        when 1; "Displaying <b>1</b> #{h(entry_name)}".html_safe
        else;   "Displaying <b>all #{total_num}</b> #{entry_name.pluralize}".html_safe
        end
      else
        "Displaying #{h(entry_name.pluralize)} <b>#{start_num} - #{end_num}</b> of <b>#{total_num}</b>".html_safe
      end
  end

  # Like the mysteriously named #page_entry_info above, but for an individual
  # item show page. Displays "showing X of Y items" message.
  # Code should call this method rather than interrogating session directly,
  # because implementation of where this data is stored/retrieved may change. 
  def item_page_entry_info
    "Showing item <b>#{session[:search][:counter].to_i} of #{format_num(session[:search][:total])}</b> from your search.".html_safe
  end
  
  # Look up search field user-displayable label
  # based on params[:qt] and configuration.
  def search_field_label(params)
    h( Blacklight.label_for_search_field(params[:search_field]) )
  end

  # Export to Refworks URL, called in _show_tools
  def refworks_export_url(document = @document)
    "http://www.refworks.com/express/expressimport.asp?vendor=#{CGI.escape(application_name)}&filter=MARC%20Format&encoding=65001&url=#{CGI.escape(catalog_path(document[:id], :format => 'refworks_marc_txt', :only_path => false))}"        
  end
  
  def render_document_class(document = @document)
   'blacklight-' + document.get(Blacklight.config[:index][:record_display_type]).parameterize rescue nil
  end

  def render_document_sidebar_partial(document = @document)
    render :partial => 'show_sidebar'
  end

  def has_search_parameters?
    !params[:q].blank? or !params[:f].blank? or !params[:search_field].blank?
  end
end
