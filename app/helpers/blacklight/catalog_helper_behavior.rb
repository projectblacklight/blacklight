# -*- encoding : utf-8 -*-
module Blacklight::CatalogHelperBehavior

  ##
  # Override the Kaminari page_entries_info helper with our own, blacklight-aware
  # implementation.
  # Displays the "showing X through Y of N" message.
  #
  # @param [RSolr::Resource] (or other Kaminari-compatible objects)
  # @return [String]
  def page_entries_info(collection, options = {})
    return unless show_pagination? collection

    entry_name = if options[:entry_name]
      options[:entry_name]
    elsif collection.respond_to? :model  # DataMapper
      collection.model.model_name.human.downcase
    elsif collection.respond_to? :model_name and !collection.model_name.nil? # AR, Blacklight::PaginationMethods
      collection.model_name.human.downcase
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

  ##
  # Get the offset counter for a document
  #
  # @param [Integer] document index
  # @return [Integer]
  def document_counter_with_offset idx, offset = nil
    offset ||= @response.start if @response
    offset ||= 0

    unless render_grouped_response? 
      idx + 1 + offset
    end
  end

  ##
  # Like #page_entries_info above, but for an individual
  # item show page. Displays "showing X of Y items" message.
  # 
  # @see #page_entries_info
  # @return [String]
  def item_page_entry_info
    t('blacklight.search.entry_pagination_info.other', :current => number_with_delimiter(search_session['counter']), :total => number_with_delimiter(search_session['total']), :count => search_session['total'].to_i).html_safe
  end

  ##
  # Look up search field user-displayable label
  # based on params[:qt] and blacklight_configuration.
  def search_field_label(params)
    h( label_for_search_field(params[:search_field]) )
  end

  ##
  # Look up the current sort field, or provide the default if none is set
  #
  # @return [Blacklight::Configuration::SortField]
  def current_sort_field
    (blacklight_config.sort_fields.values.find {|f| f.sort == @response.sort} if @response and @response.sort.present?) || blacklight_config.sort_fields[params[:sort]] || default_sort_field
  end

  ##
  # Look up the current per page value, or the default if none if set
  # 
  # @return [Integer]
  def current_per_page
    (@response.rows if @response and @response.rows > 0) || params.fetch(:per_page, default_per_page).to_i
  end

  ##
  # Get the classes to add to a document's div
  # 
  # @return [String]
  def render_document_class(document = @document)
    types = document[blacklight_config.view_config(document_index_view_type).display_type_field]

    return if types.blank?

    Array(types).map do |t|
      document_class_prefix + t.parameterize rescue nil
    end.join(' ')
  end

  def document_class_prefix
    'blacklight-'
  end

  ##
  # Render the sidebar partial for a document
  #
  # @param [SolrDocument]
  # @return [String]
  def render_document_sidebar_partial(document = @document)
    render :partial => 'show_sidebar'
  end

  ##
  # Render the main content partial for a document
  #
  # @param [SolrDocument]
  # @return [String]
  def render_document_main_content_partial(document = @document)
    render partial: 'show_main_content'
  end

  ##
  # Should we display the sort and per page widget?
  # 
  # @param [Blacklight::SolrResponse]
  # @return [Boolean]
  def show_sort_and_per_page? response = nil
    response ||= @response
    !response.empty?
  end

  ##
  # Should we display the pagination controls?
  #
  # @param [Blacklight::SolrResponse]
  # @return [Boolean]
  def show_pagination? response = nil
    response ||= @response
    response.limit_value > 0
  end

  ##
  # If no search parameters have been given, we should
  # auto-focus the user's cursor into the searchbox
  # 
  # @return [Boolean]
  def should_autofocus_on_search_box?
    controller.is_a? Blacklight::Catalog and
      action_name == "index" and
      !has_search_parameters?
  end

  ##
  # Does the document have a thumbnail to render?
  # 
  # @param [SolrDocument]
  # @return [Boolean]
  def has_thumbnail? document
    blacklight_config.view_config(document_index_view_type).thumbnail_method.present? or
      blacklight_config.view_config(document_index_view_type).thumbnail_field && document.has?(blacklight_config.view_config(document_index_view_type).thumbnail_field)
  end

  ##
  # Render the thumbnail, if available, for a document and
  # link it to the document record.
  # 
  # @param [SolrDocument]
  # @param [Hash] options to pass to the image tag
  # @param [Hash] url options to pass to #link_to_document
  # @return [String]
  def render_thumbnail_tag document, image_options = {}, url_options = {}
    value = if blacklight_config.view_config(document_index_view_type).thumbnail_method
      send(blacklight_config.view_config(document_index_view_type).thumbnail_method, document, image_options)
    elsif blacklight_config.view_config(document_index_view_type).thumbnail_field
      image_tag thumbnail_url(document), image_options
    end

    if value
      if url_options === false || url_options[:suppress_link]
        value
      else
        link_to_document document, value, url_options
      end
    end
  end

  ##
  # Get the URL to a document's thumbnail image
  # 
  # @param [SolrDocument]
  # @return [String]
  def thumbnail_url document
    if document.has? blacklight_config.view_config(document_index_view_type).thumbnail_field
      document.first(blacklight_config.view_config(document_index_view_type).thumbnail_field)
    end
  end

  ##
  # Get url parameters to a search within a grouped result set
  # 
  # @param [Blacklight::SolrResponse::Group]
  # @return [Hash]
  def add_group_facet_params_and_redirect group
    add_facet_params_and_redirect(group.field, group.key)
  end

  ##
  # Render the view type icon for the results view picker
  # 
  # @param [String]
  # @return [String]
  def render_view_type_group_icon view
    content_tag :span, '', class: "glyphicon #{blacklight_config.view[view].icon_class || default_view_type_group_icon_classes(view) }"
  end

  ##
  # Get the default view type classes for a view in the results view picker
  #
  # @param [String]
  # @return [String]
  def default_view_type_group_icon_classes view
    "glyphicon-#{view.to_s.parameterize } view-icon-#{view.to_s.parameterize}"
  end
  
  def current_bookmarks response = nil
    response ||= @response
    @current_bookmarks ||= current_or_guest_user.bookmarks_for_documents(response.documents).to_a
  end

  def is_bookmarked? document
    current_bookmarks.any? { |x| x.document_id == document.id and x.document_type == document.class }
  end
  
  def render_marc_tools
    return unless defined? Blacklight::Marc
    
    begin
      # blacklight-marc 5.4+
      render 'marc_tools'
    rescue ActionView::MissingTemplate
      # blacklight-marc 5.0+
      render('endnote') + render('refworks')
    end
  end

  def render_refworks_action? config, options = {}
    options[:document] && options[:document].respond_to?(:export_formats) && options[:document].export_formats.keys.include?(:refworks_marc_txt )
  end

  def render_endnote_action? config, options = {}
    options[:document] && options[:document].respond_to?(:export_formats) && options[:document].export_formats.keys.include?(:endnote )
  end

  def render_librarian_view_control? config, options = {}
    respond_to? :librarian_view_catalog_path and options[:document] and options[:document].respond_to?(:to_marc)
  end

end
