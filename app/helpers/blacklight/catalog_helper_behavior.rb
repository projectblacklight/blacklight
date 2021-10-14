# frozen_string_literal: true
# Helper methods for catalog-like controllers
module Blacklight::CatalogHelperBehavior
  extend Deprecation
  self.deprecation_horizon = 'blacklight 8.0'

  include Blacklight::ConfigurationHelperBehavior
  include Blacklight::ComponentHelperBehavior
  include Blacklight::FacetsHelperBehavior
  include Blacklight::RenderConstraintsHelperBehavior
  include Blacklight::RenderPartialsHelperBehavior
  include Blacklight::SearchHistoryConstraintsHelperBehavior
  include Blacklight::SuggestHelperBehavior

  # @param [Hash] options
  # @option options :route_set the route scope to use when constructing the link
  # @return [String]
  def rss_feed_link_tag(options = {})
    auto_discovery_link_tag(:rss, feed_link_url('rss', options), title: t('blacklight.search.rss_feed'))
  end

  # @param [Hash] options
  # @option options :route_set the route scope to use when constructing the link
  # @return [String]
  def atom_feed_link_tag(options = {})
    auto_discovery_link_tag(:atom, feed_link_url('atom', options), title: t('blacklight.search.atom_feed'))
  end

  # @param [Hash] options
  # @option options :route_set the route scope to use when constructing the link
  # @return [String]
  def json_api_link_tag(options = {})
    auto_discovery_link_tag(:json, feed_link_url('json', options), type: 'application/json')
  end

  ##
  # Override the Kaminari page_entries_info helper with our own, blacklight-aware
  # implementation. Why do we have to do this?
  #  - We need custom counting information for grouped results
  #  - We need to provide number_with_delimiter strings to i18n keys
  # If we didn't have to do either one of these, we could get away with removing
  # this entirely.
  #
  # @param [RSolr::Resource] collection (or other Kaminari-compatible objects)
  # @return [String]
  def page_entries_info(collection, entry_name: nil)
    entry_name = if entry_name
                   entry_name.pluralize(collection.size, I18n.locale)
                 else
                   collection.entry_name(count: collection.size).to_s
                 end

    # grouped response objects need special handling
    end_num = if collection.respond_to?(:groups) && render_grouped_response?(collection)
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
        t('blacklight.search.pagination_info.no_items_found', entry_name: entry_name).html_safe
      when 1
        t('blacklight.search.pagination_info.single_item_found', entry_name: entry_name).html_safe
      else
        t('blacklight.search.pagination_info.pages', entry_name: entry_name,
                                                     current_page: collection.current_page,
                                                     num_pages: collection.total_pages,
                                                     start_num: number_with_delimiter(collection.offset_value + 1),
                                                     end_num: number_with_delimiter(end_num),
                                                     total_num: number_with_delimiter(collection.total_count),
                                                     count: collection.total_pages).html_safe
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
  # @deprecated
  # @see #page_entries_info
  # @return [String]
  def item_page_entry_info
    t('blacklight.search.entry_pagination_info.other', current: number_with_delimiter(search_session['counter']),
                                                       total: number_with_delimiter(search_session['total']),
                                                       count: search_session['total'].to_i).html_safe
  end
  deprecation_deprecate item_page_entry_info: 'Use Blacklight::SearchContextComponent methods instead'

  ##
  # Look up search field user-displayable label
  # based on params[:qt] and blacklight_configuration.
  # @return [String]
  def search_field_label(params)
    h(label_for_search_field(params[:search_field]))
  end

  ##
  # Look up the current sort field, or provide the default if none is set
  #
  # @return [Blacklight::Configuration::SortField]
  def current_sort_field
    (blacklight_config.sort_fields.values.find { |f| f.sort == @response.sort } if @response && @response.sort.present?) || blacklight_config.sort_fields[params[:sort]] || default_sort_field
  end

  ##
  # Look up the current per page value, or the default if none if set
  #
  # @return [Integer]
  def current_per_page
    (@response.rows if @response && @response.rows > 0) || params.fetch(:per_page, blacklight_config.default_per_page).to_i
  end

  ##
  # Get the classes to add to a document's div
  #
  # @param [Blacklight::Document] document
  # @return [String]
  def render_document_class(document = @document)
    types = document_presenter(document).display_type
    return if types.blank?

    Array(types).compact.map do |t|
      "#{document_class_prefix}#{t.try(:parameterize) || t}"
    end.join(' ')
  end

  ##
  # Return a prefix for the document classes infered from the document
  # @see #render_document_class
  # @return [String]
  def document_class_prefix
    'blacklight-'
  end

  ##
  # Render the sidebar partial for a document
  #
  # @param [SolrDocument] document
  # @return [String]
  def render_document_sidebar_partial(document = nil)
    unless document
      Deprecation.warn(self, 'render_document_sidebar_partial expects one argument ' \
        '(@document) and you passed none. This behavior will be removed in version 8')
      document = @document
    end
    render 'show_sidebar', document: document
  end

  ##
  # Render the main content partial for a document
  #
  # @param [SolrDocument] _document
  # @return [String]
  def render_document_main_content_partial(_document = @document)
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
  # @deprecated
  # @return [Boolean]
  def should_autofocus_on_search_box?
    controller.is_a?(Blacklight::Catalog) &&
      action_name == "index" &&
      !has_search_parameters?
  end
  deprecation_deprecate should_autofocus_on_search_box?: "use SearchBarPresenter#autofocus?"

  ##
  # Does the document have a thumbnail to render?
  #
  # @deprecated
  # @param [SolrDocument] document
  # @return [Boolean]
  def has_thumbnail? document
    document_presenter(document).thumbnail.exists?
  end
  deprecation_deprecate has_thumbnail?: "use IndexPresenter#thumbnail.exists?"

  ##
  # Render the thumbnail, if available, for a document and
  # link it to the document record.
  #
  # @deprecated
  # @param [SolrDocument] document
  # @param [Hash] image_options to pass to the image tag
  # @param [Hash] url_options to pass to #link_to_document
  # @return [String]
  def render_thumbnail_tag document, image_options = {}, url_options = {}
    document_presenter(document).thumbnail.thumbnail_tag(image_options, url_options)
  end
  deprecation_deprecate render_thumbnail_tag: "Use IndexPresenter#thumbnail.thumbnail_tag"

  ##
  # Get the URL to a document's thumbnail image
  #
  # @deprecated
  # @param [SolrDocument] document
  # @return [String]
  def thumbnail_url document
    if document.has? blacklight_config.view_config(document_index_view_type).thumbnail_field
      document.first(blacklight_config.view_config(document_index_view_type).thumbnail_field)
    end
  end
  deprecation_deprecate thumbnail_url: "this method will be removed without replacement"

  ##
  # Render the view type icon for the results view picker
  #
  # @deprecated
  # @param [String] view
  # @return [String]
  def render_view_type_group_icon view
    blacklight_icon(view)
  end
  deprecation_deprecate render_view_type_group_icon: 'call blacklight_icon instead'

  ##
  # Get the default view type classes for a view in the results view picker
  #
  # @deprecated
  # @param [String] view
  # @return [String]
  def default_view_type_group_icon_classes view
    Deprecation.warn(Blacklight::CatalogHelperBehavior, 'This method has been deprecated, use blacklight_icons helper instead')
    "glyphicon-#{view.to_s.parameterize} view-icon-#{view.to_s.parameterize}"
  end

  ##
  # return the Bookmarks on a set of documents
  # @param [Enumerable<Blacklight::Document>] documents_or_response
  # @return [Enumerable<Bookmark>]
  def current_bookmarks documents_or_response = nil
    documents = if documents_or_response.respond_to? :documents
                  Deprecation.warn(Blacklight::CatalogHelperBehavior, "Passing a response to #current_bookmarks is deprecated; pass response.documents instead")
                  documents_or_response.documents
                else
                  documents_or_response
                end

    documents ||= [@document] if @document.present?
    documents ||= @response.documents

    @current_bookmarks ||= current_or_guest_user.bookmarks_for_documents(documents).to_a
  end

  ##
  # Check if the document is in the user's bookmarks
  # @param [Blacklight::Document] document
  # @return [Boolean]
  def bookmarked? document
    current_bookmarks.any? { |x| x.document_id == document.id && x.document_type == document.class }
  end

  # Render an html <title> appropriate string for a selected facet field and values
  #
  # @see #render_search_to_page_title
  # @param [Symbol] facet the facet field
  # @param [Array<String>] values the selected facet values
  # @return [String]
  def render_search_to_page_title_filter(facet, values)
    facet_config = facet_configuration_for_field(facet)
    filter_label = facet_field_label(facet_config.key)
    filter_value = if values.size < 3
                     values.map { |value| facet_item_presenter(facet_config, value, facet).label }.to_sentence
                   else
                     t('blacklight.search.page_title.many_constraint_values', values: values.size)
                   end
    t('blacklight.search.page_title.constraint', label: filter_label, value: filter_value)
  end

  # Render an html <title> appropriate string for a set of search parameters
  # @param [ActionController::Parameters] params2
  # @return [String]
  def render_search_to_page_title(params)
    constraints = []

    if params['q'].present?
      q_label = label_for_search_field(params[:search_field]) unless default_search_field?(params[:search_field])

      constraints += if q_label.present?
                       [t('blacklight.search.page_title.constraint', label: q_label, value: params['q'])]
                     else
                       [params['q']]
                     end
    end

    if params['f'].present?
      constraints += params['f'].to_unsafe_h.collect { |key, value| render_search_to_page_title_filter(key, Array(value)) }
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
