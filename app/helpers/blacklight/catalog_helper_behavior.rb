# frozen_string_literal: true
module Blacklight::CatalogHelperBehavior
  # @param [Hash] options 
  # @option options :route_set the route scope to use when constructing the link
  def rss_feed_link_tag(options = {})
    auto_discovery_link_tag(:rss, feed_link_url('rss', options), title: t('blacklight.search.rss_feed'))
  end

  # @param [Hash] options 
  # @option options :route_set the route scope to use when constructing the link
  def atom_feed_link_tag(options = {})
    auto_discovery_link_tag(:atom, feed_link_url('atom', options), title: t('blacklight.search.atom_feed'))
  end

  # @param [Hash] options
  # @option options :route_set the route scope to use when constructing the link
  def json_api_link_tag(options = {})
    auto_discovery_link_tag(:json, feed_link_url('json', options), type: 'application/json')
  end

  ##
  # Override the Kaminari page_entries_info helper with our own, blacklight-aware
  # implementation.
  # Displays the "showing X through Y of N" message.
  #
  # @param [RSolr::Resource] collection (or other Kaminari-compatible objects)
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
      when 0
        t('blacklight.search.pagination_info.no_items_found', :entry_name => entry_name ).html_safe
      when 1
        t('blacklight.search.pagination_info.single_item_found', :entry_name => entry_name).html_safe
      else
        t('blacklight.search.pagination_info.pages', :entry_name => entry_name,
                                                     :current_page => collection.current_page,
                                                     :num_pages => collection.total_pages,
                                                     :start_num => number_with_delimiter(collection.offset_value + 1),
                                                     :end_num => number_with_delimiter(end_num),
                                                     :total_num => number_with_delimiter(collection.total_count),
                                                     :count => collection.total_pages).html_safe
    end
  end

  ##
  # Get the offset counter for a document
  #
  # @param [Integer] idx document index
  # @param [Integer] offset additional offset to incremenet the counter by
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
    t('blacklight.search.entry_pagination_info.other', :current => number_with_delimiter(search_session['counter']),
                                                       :total => number_with_delimiter(search_session['total']),
                                                       :count => search_session['total'].to_i).html_safe
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

    Array(types).compact.map do |t|
      "#{document_class_prefix}#{t.try(:parameterize) || t}"
    end.join(' ')
  end

  def document_class_prefix
    'blacklight-'
  end

  ##
  # Render the sidebar partial for a document
  #
  # @param [SolrDocument] document
  # @return [String]
  def render_document_sidebar_partial(document = @document)
    render :partial => 'show_sidebar'
  end

  ##
  # Render the main content partial for a document
  #
  # @param [SolrDocument] document
  # @return [String]
  def render_document_main_content_partial(document = @document)
    render partial: 'show_main_content'
  end

  ##
  # Should we display the sort and per page widget?
  # 
  # @param [Blacklight::Solr::Response] response
  # @return [Boolean]
  def show_sort_and_per_page? response = nil
    response ||= @response
    !response.empty?
  end

  ##
  # Should we display the pagination controls?
  #
  # @param [Blacklight::Solr::Response] response
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
  # @param [SolrDocument] document
  # @return [Boolean]
  def has_thumbnail? document
    blacklight_config.view_config(document_index_view_type).thumbnail_method.present? or
      blacklight_config.view_config(document_index_view_type).thumbnail_field && document.has?(blacklight_config.view_config(document_index_view_type).thumbnail_field)
  end

  ##
  # Render the thumbnail, if available, for a document and
  # link it to the document record.
  # 
  # @param [SolrDocument] document
  # @param [Hash] image_options to pass to the image tag
  # @param [Hash] url_options to pass to #link_to_document
  # @return [String]
  def render_thumbnail_tag document, image_options = {}, url_options = {}
    value = if blacklight_config.view_config(document_index_view_type).thumbnail_method
      send(blacklight_config.view_config(document_index_view_type).thumbnail_method, document, image_options)
    elsif blacklight_config.view_config(document_index_view_type).thumbnail_field
      url = thumbnail_url(document)

      image_tag url, image_options if url.present?
    end

    if value
      if url_options == false
        Deprecation.warn(self, "passing false as the second argument to render_thumbnail_tag is deprecated. Use suppress_link: true instead. This behavior will be removed in Blacklight 7")
        url_options = { suppress_link: true }
      end
      if url_options[:suppress_link]
        value
      else
        link_to_document document, value, url_options
      end
    end
  end

  ##
  # Get the URL to a document's thumbnail image
  # 
  # @param [SolrDocument] document
  # @return [String]
  def thumbnail_url document
    if document.has? blacklight_config.view_config(document_index_view_type).thumbnail_field
      document.first(blacklight_config.view_config(document_index_view_type).thumbnail_field)
    end
  end

  ##
  # Render the view type icon for the results view picker
  # 
  # @param [String] view
  # @return [String]
  def render_view_type_group_icon view
    content_tag :span, '', class: "glyphicon #{blacklight_config.view[view].icon_class || default_view_type_group_icon_classes(view)}"
  end

  ##
  # Get the default view type classes for a view in the results view picker
  #
  # @param [String] view
  # @return [String]
  def default_view_type_group_icon_classes view
    "glyphicon-#{view.to_s.parameterize} view-icon-#{view.to_s.parameterize}"
  end
  
  def current_bookmarks response = nil
    response ||= @response
    @current_bookmarks ||= current_or_guest_user.bookmarks_for_documents(response.documents).to_a
  end

  ##
  # Check if the document is in the user's bookmarks
  def bookmarked? document
    current_bookmarks.any? { |x| x.document_id == document.id and x.document_type == document.class }
  end

  def render_search_to_page_title_filter(facet, values)
    facet_config = facet_configuration_for_field(facet)
    filter_label = facet_field_label(facet_config.key)
    filter_value = if values.size < 3
      values.map {|value| facet_display_value(facet, value)}.to_sentence
    else 
      t('blacklight.search.page_title.many_constraint_values', values: values.size)
    end
    t('blacklight.search.page_title.constraint', label: filter_label, value: filter_value)
  end

  def render_search_to_page_title(params)
    constraints = []

    if params['q'].present?
      q_label = label_for_search_field(params[:search_field]) unless default_search_field && params[:search_field] == default_search_field[:key]

      constraints += if q_label.present?
                       [t('blacklight.search.page_title.constraint', label: q_label, value: params['q'])]
                     else
                       [params['q']]
                     end
    end

    if params['f'].present?
      constraints += params['f'].to_unsafe_h.collect { |key, value| render_search_to_page_title_filter(key, value) }
    end

    constraints.join(' / ')
  end

  private

    # @param [String] format 
    # @param [Hash] options 
    # @option options :route_set the route scope to use when constructing the link
    def feed_link_url(format, options = {})
      scope = options.delete(:route_set) || self
      scope.url_for search_state.to_h.merge(format: format)
    end
end
