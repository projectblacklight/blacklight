# frozen_string_literal: true

# Helper methods for catalog-like controllers
module Blacklight::CatalogHelperBehavior
  include Blacklight::ConfigurationHelperBehavior
  include Blacklight::ComponentHelperBehavior
  include Blacklight::DocumentHelperBehavior
  include Blacklight::FacetsHelperBehavior
  include Blacklight::RenderPartialsHelperBehavior

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
  # @param [ActionController::Parameters] params
  # @return [String]
  def render_search_to_page_title(search_state_or_params)
    search_state = if search_state_or_params.is_a? Blacklight::SearchState
                     search_state_or_params
                   else
                     controller.search_state_class.new(params, blacklight_config, self)
                   end

    constraints = []

    if search_state.query_param.present?
      q_label = label_for_search_field(search_state.search_field.key) unless search_state.search_field&.key.blank? || default_search_field?(search_state.search_field.key)

      constraints += if q_label.present?
                       [t('blacklight.search.page_title.constraint', label: q_label, value: search_state.query_param)]
                     else
                       [search_state.query_param]
                     end
    end

    if search_state.filters.any?
      constraints += search_state.filters.collect { |filter| render_search_to_page_title_filter(filter.key, filter.values) }
    end

    constraints.join(' / ')
  end

  ##
  # Should we render a grouped response (because the response
  # contains a grouped response instead of the normal response)
  #
  # Default to false if there's no response object available (sometimes the case
  #   for tests, but might happen in other circumstances too..)
  # @return [Boolean]
  def render_grouped_response? response = @response
    response&.grouped?
  end

  ##
  # Get the current "view type" (and ensure it is a valid type)
  #
  # @param [Hash] query_params the query parameters to check
  # @return [Symbol]
  def document_index_view_type query_params = params || {}
    view_param = query_params[:view]
    view_param ||= session[:preferred_view] if respond_to?(:session)
    if view_param && document_index_views.key?(view_param.to_sym)
      view_param.to_sym
    else
      default_document_index_view_type
    end
  end

  # Should we display special "home" splash screen content, instead of search results?
  def display_splash_content?
    !has_search_parameters?
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
