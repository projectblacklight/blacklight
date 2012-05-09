# -*- encoding : utf-8 -*-
module Blacklight::CatalogHelperBehavior

  # Pass in an RSolr::Response (or duck-typed similar) object, 
  # it translates to a Kaminari-paginatable
  # object, with the keys Kaminari views expect. 
  def paginate_params(response)
    per_page = response.rows
    per_page = 1 if per_page < 1
    current_page = (response.start / per_page).ceil + 1
    num_pages = (response.total / per_page.to_f).ceil
    Struct.new(:current_page, :num_pages, :limit_value).new(current_page, num_pages, per_page)
  end    

  # Equivalent to kaminari "paginate", but takes an RSolr::Response as first argument. 
  # Will convert it to something kaminari can deal with (using #paginate_params), and
  # then call kaminari paginate with that. Other arguments (options and block) same as
  # kaminari paginate, passed on through. 
  # will output HTML pagination controls. 
  def paginate_rsolr_response(response, options = {}, &block)
    paginate paginate_params(response), options, &block
  end

  #
  # shortcut for built-in Rails helper, "number_with_delimiter"
  #
  def format_num(num); number_with_delimiter(num) end

  #
  # Pass in an RSolr::Response. Displays the "showing X through Y of N" message. 
  def render_pagination_info(response, options = {})
      start = response.start + 1
      per_page = response.rows
      current_page = (response.start / per_page).ceil + 1
      num_pages = (response.total / per_page.to_f).ceil
      total_hits = response.total

      start_num = format_num(start)
      end_num = format_num(start + response.docs.length - 1)
      total_num = format_num(total_hits)

   # TODO: i18n the entry_name
      entry_name = options[:entry_name] ||
        (response.empty?? t('entry_name.default') : response.docs.first.class.name.underscore.sub('_', ' '))

      case response.docs.length
        when 0; t('search.pagination_info.no_items_found', :entry_name => entry_name.pluralize ).html_safe
        when 1; t('search.pagination_info.single_item_found', :entry_name => entry_name).html_safe
        else; t('search.pagination_info.pages', :entry_name => entry_name.pluralize, :current_page => current_page, :num_pages => num_pages, :start_num => start_num, :end_num => end_num, :total_num => total_num, :count => num_pages).html_safe
      end
  end

  # Like  #render_pagination_info above, but for an individual
  # item show page. Displays "showing X of Y items" message. Actually takes
  # data from session though (not a great design). 
  # Code should call this method rather than interrogating session directly,
  # because implementation of where this data is stored/retrieved may change. 
  def item_page_entry_info
    t('search.entry_pagination_info.other', :current => format_num(session[:search][:counter]), :total => format_num(session[:search][:total]), :count => session[:search][:total].to_i).html_safe
  end
  
  # Look up search field user-displayable label
  # based on params[:qt] and blacklight_configuration.
  def search_field_label(params)
    h( label_for_search_field(params[:search_field]) )
  end

  # Export to Refworks URL, called in _show_tools
  def refworks_export_url(document = @document)
    "http://www.refworks.com/express/expressimport.asp?vendor=#{CGI.escape(application_name)}&filter=MARC%20Format&encoding=65001&url=#{CGI.escape(catalog_path(document, :format => 'refworks_marc_txt', :only_path => false))}"        
  end
  
  def render_document_class(document = @document)
   'blacklight-' + document.get(blacklight_config.index.record_display_type).parameterize rescue nil
  end

  def render_document_sidebar_partial(document = @document)
    render :partial => 'show_sidebar'
  end

  def has_search_parameters?
    !params[:q].blank? or !params[:f].blank? or !params[:search_field].blank?
  end
end
