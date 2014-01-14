# -*- encoding : utf-8 -*-
module Blacklight::CatalogHelperBehavior

  # Equivalent to kaminari "paginate", but takes an RSolr::Response as first argument.
  # Will convert it to something kaminari can deal with (using #paginate_params), and
  # then call kaminari paginate with that. Other arguments (options and block) same as
  # kaminari paginate, passed on through.
  # will output HTML pagination controls.
  def paginate_rsolr_response(response, options = {}, &block)
    paginate response, options, &block
  end

  # Override the Kaminari page_entries_info helper with our own, blacklight-aware
  # implementation
  #
  # Pass in an RSolr::Response. Displays the "showing X through Y of N" message.
  def page_entries_info(collection, options = {})
    entry_name = if options[:entry_name]
      options[:entry_name]
    elsif collection.respond_to? :model  # DataMapper
        collection.model.model_name.human.downcase
    elsif collection.respond_to? :model_name and !collection.model_name.nil? # AR, Blacklight::PaginationMethods
        collection.model_name.human.downcase
    elsif collection.is_a?(::Kaminari::PaginatableArray)
      'entry'
    else
      t('blacklight.entry_name.default')
    end

    entry_name = entry_name.pluralize unless collection.total_count == 1

    # grouped response objects need special handling
    end_num = if collection.respond_to? :groups and render_grouped_response? collection
      collection.groups.length
    else
      collection.limit_value
    end

    end_num = if collection.offset_value + end_num <= collection.total_count
      collection.offset_value + end_num
    else
      collection.total_count
    end
      
    case collection.total_count
      when 0; t('blacklight.search.pagination_info.no_items_found', :entry_name => entry_name ).html_safe
      when 1; t('blacklight.search.pagination_info.single_item_found', :entry_name => entry_name).html_safe
      else; t('blacklight.search.pagination_info.pages', :entry_name => entry_name, :current_page => collection.current_page, :num_pages => collection.total_pages, :start_num => number_with_delimiter(collection.offset_value + 1) , :end_num => number_with_delimiter(end_num), :total_num => number_with_delimiter(collection.total_count), :count => collection.total_pages).html_safe
    end
  end

  def document_counter_with_offset idx 
    unless render_grouped_response? 
      idx + 1 + @response.params[:start].to_i
    end
  end

  # Like  #page_entries_info above, but for an individual
  # item show page. Displays "showing X of Y items" message. Actually takes
  # data from session though (not a great design).
  # Code should call this method rather than interrogating session directly,
  # because implementation of where this data is stored/retrieved may change.
  def item_page_entry_info
    t('blacklight.search.entry_pagination_info.other', :current => number_with_delimiter(search_session[:counter]), :total => number_with_delimiter(search_session[:total]), :count => search_session[:total].to_i).html_safe
  end

  # Look up search field user-displayable label
  # based on params[:qt] and blacklight_configuration.
  def search_field_label(params)
    h( label_for_search_field(params[:search_field]) )
  end

  def current_sort_field
    blacklight_config.sort_fields[params[:sort]] || (blacklight_config.sort_fields.first ? blacklight_config.sort_fields.first.last : nil )
  end

  def current_per_page
    (@response.rows if @response and @response.rows > 0) || params.fetch(:per_page, (blacklight_config.per_page.first unless blacklight_config.per_page.blank?)).to_i
  end

  # Export to Refworks URL, called in _show_tools
  def refworks_export_url(document = @document)
    "http://www.refworks.com/express/expressimport.asp?vendor=#{CGI.escape(application_name)}&filter=MARC%20Format&encoding=65001&url=#{CGI.escape(polymorphic_path(document, :format => 'refworks_marc_txt', :only_path => false))}"
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

  def show_sort_and_per_page? response = nil
    response ||= @response
    response.total > 1
  end

  def should_autofocus_on_search_box?
    controller.is_a? Blacklight::Catalog and
      action_name == "index" and
      params[:q].to_s.empty? and
      params[:f].to_s.empty?
  end

  def has_thumbnail? document
    blacklight_config.index.thumbnail_method or
      blacklight_config.index.thumbnail_field && document.has?(blacklight_config.index.thumbnail_field)
  end

  def render_thumbnail_tag document, image_options = {}, url_options = {}
    value = if blacklight_config.index.thumbnail_method
      send(blacklight_config.index.thumbnail_method, document, image_options)
    elsif blacklight_config.index.thumbnail_field
      image_tag thumbnail_url(document), image_options
    end

    if value
      link_to_document document, url_options.merge(:label => value)
    end
  end

  def thumbnail_url document
    if document.has? blacklight_config.index.thumbnail_field
      document.first(blacklight_config.index.thumbnail_field)
    end
  end

  def add_group_facet_params_and_redirect group
    add_facet_params_and_redirect(group.field, group.key)
  end

  def response_has_no_search_results?
    @response.total == 0 
  end
end
