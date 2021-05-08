# frozen_string_literal: true
# Helper methods for catalog-like controllers
module Blacklight::CatalogHelperBehavior
  include Blacklight::ConfigurationHelperBehavior
  include Blacklight::ComponentHelperBehavior
  include Blacklight::FacetsHelperBehavior
  include Blacklight::RenderPartialsHelperBehavior
  include Blacklight::SearchHistoryConstraintsHelperBehavior

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
                   collection.entry_name(count: collection.size).to_s.downcase
                 end

    entry_name = entry_name.pluralize unless collection.total_count == 1

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
  def render_document_sidebar_partial(document)
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
  # return the Bookmarks on a set of documents (all bookmarks on the page)
  # @private
  # @return [Enumerable<Bookmark>]
  def current_bookmarks
    @current_bookmarks ||= begin
      documents = @document.presence || @response.documents
      current_or_guest_user.bookmarks_for_documents(Array(documents)).to_a
    end
  end
  private :current_bookmarks

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
